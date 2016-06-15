FROM busybox

ADD pub-artefact /

ADD swagger.json /artefact/swagger.json 
RUN ["/bin/busybox","sh","/pub-artefact","/artefact","/usr/share/nginx/html/doc/swagger/onezone"]
RUN ["/bin/busybox","sh","/pub-artefact","/artefact","/var/www/html/docs/doc/swagger/onezone"]

#ADD generated/static/onezone-static.html /artefact/generated/static/onezone-static.html

#RUN ["/bin/busybox","sh","/pub-artefact","/artefact/generated/static","/usr/share/nginx/html/doc/advanced/rest/swagger-static-onezone"]
#RUN ["/bin/busybox","sh","/pub-artefact","/artefact/generated/static","/var/www/html/docs/doc/advanced/rest/swagger-static-onezone"]

#Otherwise docer-compose up fails randomly, seems to work with docker 1.10+
CMD ["/bin/busybox","tail","-f","/dev/null"]
