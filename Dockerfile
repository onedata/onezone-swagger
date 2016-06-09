FROM busybox

ADD pub-artefact /

ADD swagger.json /artefact/swagger.json 
RUN ["/bin/busybox","sh","/pub-artefact","/artefact/swagger.json","/usr/share/nginx/html/doc/swagger/onezone/swagger.json"]

ADD generated/static/onezone-static.html /artefact/generated/static/onezone-static.html

RUN ["/bin/busybox","sh","/pub-artefact","/artefact/generated/static/onezone-static.html","/usr/share/nginx/html/doc/advanced/rest/onezone-static.html"]
