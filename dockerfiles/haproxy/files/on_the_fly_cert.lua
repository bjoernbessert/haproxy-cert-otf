
local http = require("socket.http")

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

function get_cert_via_http()

    core.log(core.info, "Get Cert via HTTP ...")

     local result, respcode, respheaders = http.request {
                --- url = "http://" .. addr .. path,
                --- url = "http://internal-ca.example.local/ca-api/v1/getcert?domain=sub1.example.local",
                url = "http://192.168.217.131/sub1.example.local.pem",
                create = create_sock,
                -- Disable redirects, because DNS does not work here.
                redirect = false
     }

    --- print( result )
    --- print( respcode )
    --- print( respheaders )

    if result == nil then
      core.log(core.info, "Failure in HTTP Request")
    else

      if respcode ~= 200 then
	core.log(core.info, "Not expected HTTP Statuscode: " .. respcode)
      end

      if respcode == 200 then
          --- move downloaded cert to haproxy cert dir
          core.log(core.info, "Execute HAProxy reload ...")
          os.execute('/usr/bin/timeout 5 /usr/bin/supervisorctl restart haproxy_back')
      end

    end
end

function get_cert_from_local_ca(domain)
	
    core.log(core.info, "Generate Cert trough local CA for domain: " .. domain)
    os.execute('/usr/bin/timeout 5 /opt/generate-cert/create-cert.sh ' .. domain)
	
end

function cert_otf(txn, arg)

   core.log(core.info, "SNI detected: " .. txn.sf:req_ssl_sni())

   local sni_value = txn.sf:req_ssl_sni()

   local cert_file = "/etc/haproxy/certs/" .. sni_value .. ".pem"

   --- core.log(core.info, cert_file)

   cert_file_existing = io.open(cert_file, "r")

   if cert_file_existing == nil then

     core.log(core.info, "WARNING: No Cert found, generating one")

     --- TODO: Choose method here by variable

     --- get_cert_via_http()
     get_cert_from_local_ca(sni_value)

   else
     core.log(core.info, "OK: Cert already there")
   end


end

core.register_action("cert_otf", { "tcp-req" }, cert_otf)

