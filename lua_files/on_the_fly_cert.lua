--- Supported values: local_ca, http
local get_cert_method = 'local_ca'

local haproxy_certs_dir = "/etc/haproxy/certs/"
local haproxy_reload_cmd = '/usr/bin/timeout 5 /usr/bin/supervisorctl restart haproxy_back'
local cert_generate_cmd = '/usr/bin/timeout 5 /opt/generate-cert/create-cert.sh '

local http = require("socket.http")
local io = require("io")
local ltn12 = require("ltn12")

function get_cert_via_http(domain)
    core.log(core.info, "Get Cert via HTTP ...")

    local tmp_workspace_dir = '/var/tmp/'
    local cert_filename = domain .. ".pem"
    local fullpath_tmp = tmp_workspace_dir .. cert_filename
    local fh = io.open(fullpath_tmp, "wb")

    --- local host = 'internal-ca.example.local'
    local host = '172.17.0.1'
    local port = 8081
    --- local path = '/ca-api/v1/getcert/' .. domain
    local path = '/ca-api/v1/getcert/sub1.example.local'
    local addr = host .. ":" .. port

    http.TIMEOUT = 8
    local result, respcode, respheaders = http.request {
                --- Request certificate from API and get back PEM-File (Content-Type: text/plain)
                url = "http://" .. addr .. path,
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

          else
              --- TODO: Sometimes this is triggered when requests for the same FQDN arrive at the same time 
              -- for the first time, but its not critical. Solvable with locking mechanism.
              core.log(core.info, "WARNING: Move cert operation not successful!")
              error("Exited with error")
          end

      end

    end
end

function get_cert_from_local_ca(domain)
    core.log(core.info, "Generate Cert trough local CA for domain: " .. domain)
    local success, term_type, rc_code = os.execute(cert_generate_cmd .. domain)
    if rc_code ~= 0 then
        error("Error while generating Cert trough local CA!: " .. tostring(success) .. " " .. tostring(term_type) .. " " .. tostring(rc_code))
    end
end


function set_lock()
    core.log(core.info, "Setting lock")
    --- TODO: To be implemented
end

function remove_lock()
    core.log(core.info, "Removing lock")
    --- TODO: To be implemented
end

function errorhandler(err)
    print( "ERROR:", err )
end

function cert_otf(txn)
    core.log(core.info, "SNI detected: " .. txn.sf:req_ssl_sni())

    local sni_value = txn.sf:req_ssl_sni()
    local cert_file = haproxy_certs_dir .. sni_value .. ".pem"

    cert_file_existing = io.open(cert_file, "r")
    if cert_file_existing == nil then
        core.log(core.info, "INFORMATIONAL: No Cert found, generating one")

        if get_cert_method == 'local_ca' then
            set_lock()
            xpcall(get_cert_from_local_ca, errorhandler, sni_value)
            remove_lock()
        elseif get_cert_method == 'http' then
            set_lock()
            xpcall(get_cert_via_http, errorhandler, sni_value)
            remove_lock()
        else
            core.log(core.info, "CRITICAL: No supported cert generation method found. Not generating any cert!")
        end
		
    else
        core.log(core.info, "OK: Cert already there")
    end

end

core.register_action("cert_otf", { "tcp-req" }, cert_otf)
