# haproxy-cert-otf

Create ssl certificates on the fly with HAProxy. Certs are generated dynamically on the first request.

### Motivation

- Internal Domains

    - No wildcard certs possible, because of domain structure with multiple (sub)levels

- Internal Root-CA which creates certs and is imported in clients (browsers etc.) 

- Why 2 HAProxy processes?

  - At the moment its not possible in HAProxy to add certs at runtime, a reload is needed after adding a cert. This feature will be possible available in HAProxy 1.9.
    - If you have a single HAProxy instance, you can't reload this instance itself, because an connection is already established and would be stay on the old process and will not get the newly generated cert
