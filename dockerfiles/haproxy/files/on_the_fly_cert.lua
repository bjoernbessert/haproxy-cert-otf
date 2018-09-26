
--- Supported values: local_ca, http
local get_cert_method = 'local_ca'

--- local haproxy_reload_cmd = ''

local http = require("socket.http")
local io = require("io")
local ltn12 = require("ltn12")


--- Monkey Patches around bugs in haproxy's Socket class
-- This function calls core.tcp(), fixes a few methods and
-- returns the resulting socket.
-- @return Socket
function create_sock()
        local sock = core.tcp()

        -- https://www.mail-archive.com/haproxy@formilux.org/msg28574.html
        sock.old_receive = sock.receive
        sock.receive = function(socket, pattern, prefix)
                local a, b
                if pattern == nil then pattern = "*l" end
                if prefix == nil then
                        a, b = sock:old_receive(pattern)
                else
                        a, b = sock:old_receive(pattern, prefix)
                end
                return a, b
        end

        -- https://www.mail-archive.com/haproxy@formilux.org/msg28604.html
        sock.old_settimeout = sock.settimeout
        sock.settimeout = function(socket, timeout)
                socket:old_settimeout(timeout)

                return 1
        end

        return sock
end

function get_cert_via_http(domain)

    core.log(core.info, "Get Cert via HTTP ...")

    local tmp_workspace_dir = '/var/tmp/'
    local cert_filename = domain .. ".pem"
    local fullpath_tmp = tmp_workspace_dir .. cert_filename
    local fh = io.open(fullpath_tmp, "wb")

    local result, respcode, respheaders = http.request {
                --- Request certificate from API and get back PEM-File (Content-Type: text/plain)
		--- url = "http://internal-ca.example.local/ca-api/v1/getcert/" .. domain,
		--- url = "http://internal-ca.example.local/ca-api/v1/getcert/sub1.example.local",
		--- url = "http://172.17.0.1/ca-api/v1/getcert/" .. domain,
		url = "http://172.17.0.1/ca-api/v1/getcert/sub1.example.local",
		--- sink = ltn12.sink.file(io.stdout),
		sink = ltn12.sink.file(fh),
                create = create_sock,
                -- Disable redirects, because DNS does not work here.
                redirect = false
    }

    core.log(core.info, "HTTP-Response Status:" .. respcode)
    
    if result == nil then
        core.log(core.info, "Failure in http.request call")
    else

      if respcode ~= 200 then
          core.log(core.info, "CRITICAL: Not expected HTTP Statuscode: " .. respcode)
      end

      if respcode == 200 then

	  local haproxy_certs_dir = "/etc/haproxy/certs/"
          local fullpath_dst = haproxy_certs_dir .. cert_filename

	  core.log(core.info, "Move cert from tempdir to HAProxy cert dir ...")
          move_cert = os.rename(fullpath_tmp, fullpath_dst)

	  if move_cert then
              core.log(core.info, "Execute HAProxy reload ...")
              os.execute('/usr/bin/timeout 5 /usr/bin/supervisorctl restart haproxy_back')
          else
              --- TODO: Sometimes this is triggered when requests for the same FQDN arrive at the same time 
	      -- for the first time, but its not critical. Solvable with locking mechanism.
              core.log(core.info, "WARNING: Move cert operation not successful!")
          end

      end

    end
end

function get_cert_from_local_ca(domain)
	
    core.log(core.info, "Generate Cert trough local CA for domain: " .. domain)
    os.execute('/usr/bin/timeout 5 /opt/generate-cert/create-cert.sh ' .. domain)
	
end

function cert_otf(txn)

   core.log(core.info, "SNI detected: " .. txn.sf:req_ssl_sni())
   local sni_value = txn.sf:req_ssl_sni()

   local cert_file = "/etc/haproxy/certs/" .. sni_value .. ".pem"
   --- core.log(core.info, cert_file)

   cert_file_existing = io.open(cert_file, "r")
   if cert_file_existing == nil then

       core.log(core.info, "INFORMATIONAL: No Cert found, generating one")

       --- Choose method
       if get_cert_method == 'local_ca' then
           get_cert_from_local_ca(sni_value)
       elseif get_cert_method == 'http' then
           get_cert_via_http(sni_value)
       else
           core.log(core.info, "CRITICAL: No supported cert generation method found. Not generating any cert!")
       end

   else
     core.log(core.info, "OK: Cert already there")
   end

end

core.register_action("cert_otf", { "tcp-req" }, cert_otf)
