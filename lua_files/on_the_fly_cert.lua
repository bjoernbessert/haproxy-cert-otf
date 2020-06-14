local get_cert_method = os.getenv("GET_CERT_METHOD")
core.log(core.info, "'GET_CERT_METHOD' env var value is: " .. tostring(get_cert_method))
local host_internal_ca = os.getenv("HOST_INTERNAL_CA")
core.log(core.info, "'HOST_INTERNAL_CA' env var value is: " .. tostring(host_internal_ca))

if (get_cert_method == nil) or not (get_cert_method == 'localca' or get_cert_method == 'http') then
    core.log(core.info, "Setting 'localca' as default/fallback")
    get_cert_method = 'localca'
end
core.log(core.info, "Use cert generation method: " .. get_cert_method)


local haproxy_certs_dir = "/etc/haproxy/certs/"
local haproxy_reload_cmd = '/usr/bin/timeout 5 /usr/bin/supervisorctl restart haproxy_back'

local cert_generate_cmd = '/usr/bin/timeout 5 /opt/generate-cert/create-cert.sh '


local http = require("socket.http")
local io = require("io")
local ltn12 = require("ltn12")

local socket = require('socket')


--- Create Map file when HAProxy loads the lua-file at startup
---TODO: Map.new fails in first attempt, second call then is everytime successfully. Bug in HAProxy Lua Map class?
function create_map()
    lockmap = Map.new("/tmp/lock.map", Map._str)
end

if pcall(create_map) then
    core.log(core.info, "create_map: Success")
else
    core.log(core.info, "create_map: Failure")
    create_map()
    core.log(core.info, "create_map: After 2nd try")
    core.set_map("/tmp/lock.map", 'lock_cert', 'no')
end

core.log(core.info, "Things at startup done.")


function dns_query(name_to_resolve) 
    --- POSIX Systemcall to gethostbyaddr
    --- Timeout values for socket.dns.toip: Cannot be changed because there isn't a timeout for a syscall in luasocket
    --- The timeout value which is in effect here is those from the system settings (from /etc/resolv.conf)
    core.log(core.info, "Doing DNS Request for " .. tostring(name_to_resolve) .. "...")        
    local ip_tbl = socket.dns.toip(name_to_resolve)
    core.log(core.info, "ip_tbl: " .. tostring(ip_tbl))
    return ip_tbl
end

function get_cert_via_http(domain)
    core.log(core.info, "Get Cert via HTTP ...")

    local tmp_workspace_dir = '/var/tmp/'
    local cert_filename = domain .. ".pem"
    local fullpath_tmp = tmp_workspace_dir .. cert_filename
    local fh = io.open(fullpath_tmp, "wb")
    local host_ip = dns_query(host_internal_ca)
    local port = 8081
    local path = '/ca-api/v1/getcert/' .. domain
    --- local path = '/ca-api/v1/getcert/sub1.example.local'
    local addr = host_ip .. ":" .. port

    local url = "http://" .. addr .. path
    core.log(core.info, "Call url: " .. url)

    http.TIMEOUT = 8
    local result, respcode, respheaders = http.request {
                --- Request certificate from API and get back PEM-File (Content-Type: text/plain)
                url = url,
		sink = ltn12.sink.file(fh),
                create = core.tcp,
                -- Disable redirects, because DNS does not work here.
                redirect = false
    }

    core.log(core.info, "HTTP-Response Status: " .. respcode)
 
    if result == nil then
        core.log(core.info, "CRITICAL: Failure or timeout in http.request call")
        error("Exited with error")
    else

      if respcode ~= 200 then
          core.log(core.info, "CRITICAL: Not expected HTTP Statuscode: " .. respcode)
          error("Exited with error")
      end

      if respcode == 200 then

          local fullpath_dst = haproxy_certs_dir .. cert_filename

          core.log(core.info, "Move cert from tempdir to HAProxy cert dir ...")
          move_cert = os.rename(fullpath_tmp, fullpath_dst)

          if move_cert then
              core.log(core.info, "Execute HAProxy reload ...")
              os.execute(haproxy_reload_cmd)
              core.msleep(2000)

          else
              --- TODO: Sometimes this is triggered when requests for the same FQDN arrive at the same time 
              -- for the first time, but its not critical. Solvable with locking mechanism.
              core.log(core.info, "WARNING: Move cert operation not successful!")
              error("Exited with error")
          end

      end

    end
end

function get_cert_from_localca(domain)
    core.log(core.info, "Generate Cert trough local CA for domain: " .. domain)

    local success, term_type, rc_code = os.execute(cert_generate_cmd .. domain)
    if rc_code ~= 0 then
        error("Error while generating Cert trough local CA!: " .. tostring(success) .. " " .. tostring(term_type) .. " " .. tostring(rc_code))
    end
end

function check_if_lock_is_set()
    core.log(core.info, "Check for existing lock")

    local lockstatus = Map.lookup(lockmap, 'lock_cert')

    local maxretries = 10
    local n = 0

    --- wait-loop till lock is free
    while n < maxretries do
        if lockstatus == 'yes' then
            core.log(core.info, "lock is set, wait ... (" .. n .. ")")
            n = n + 1
            --- Using sleep function from luasocket
            socket.sleep(0.5)
        else
            core.log(core.info, "No lock is set, not enter/breaking the wait-loop ...")
            return true;
        end
    end

end

function set_lock()
    core.log(core.info, "Try to set lock")

    local status = check_if_lock_is_set()
    core.log(core.info, "check_if_lock_is_set() status: " .. tostring(status))

    if status then
        core.log(core.info, "Setting the lock.")
        core.set_map("/tmp/lock.map", 'lock_cert', 'yes')
        return true
    else
        core.log(core.info, "Lock not free. Cannot set lock.")
        return false
    end

end

function remove_lock()
    core.log(core.info, "Removing lock: Start")

    local lockstatus = Map.lookup(lockmap, 'lock_cert')
    core.log(core.info, "Lock status before removal task: " .. tostring(lockstatus))

    core.set_map("/tmp/lock.map", 'lock_cert', 'no')

    local lockstatus = Map.lookup(lockmap, 'lock_cert')
    core.log(core.info, "Lock status after removal task: " .. tostring(lockstatus))

    core.log(core.info, "Removing lock: End")
end

function errorhandler(err)
    print( "ERROR:", err )
end

function cert_otf(txn)
    core.log(core.info, "SNI detected: " .. txn.sf:req_ssl_sni())

    local lockstatus = Map.lookup(lockmap, 'lock_cert')
    core.log(core.info, "Lock status: " .. tostring(lockstatus))

    local sni_value = txn.sf:req_ssl_sni()
    local cert_file = haproxy_certs_dir .. sni_value .. ".pem"

    cert_file_existing = io.open(cert_file, "r")

    if cert_file_existing ~= nil then
        core.log(core.info, "OK: Cert already there")
	return
    end

    core.log(core.info, "INFORMATIONAL: No Cert found, generating one")

        if get_cert_method == 'localca' then
            local lock_could_be_set = set_lock()
            -- Debugging
            local lockstatus = Map.lookup(lockmap, 'lock_cert')
            core.log(core.info, "Lock status after set_lock(): " .. tostring(lockstatus))

            if lock_could_be_set then
                xpcall(get_cert_from_localca, errorhandler, sni_value)
                remove_lock()
	    else
                core.log(core.info, "CRITICAL: Lock could not be set.")
            end
        elseif get_cert_method == 'http' then
            local lock_could_be_set = set_lock()
            -- Debugging
            local lockstatus = Map.lookup(lockmap, 'lock_cert')
            core.log(core.info, "Lock status after set_lock(): " .. tostring(lockstatus))

            if lock_could_be_set then
                xpcall(get_cert_via_http, errorhandler, sni_value)
                remove_lock()
	    else
                core.log(core.info, "CRITICAL: Lock could not be set.")
            end
        else
            core.log(core.info, "CRITICAL: No supported cert generation method found. Not generating any cert!")
        end

end

core.register_action("cert_otf", { "tcp-req" }, cert_otf)
