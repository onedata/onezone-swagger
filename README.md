# Onezone REST API defined using Swagger (http://swagger.io)

This repo contains Swagger specification of Onezone REST API

Onezone is part of [Onedata](http://onedata.org), a distributed data management platform. Onezone enables creation of federations of storage providers, whose users can store and access data among their resources.

For more details about Onezone service please check (http://github.com/onedata/onezone)

Compiling (Using Onedata docker repository):
```
./build.sh
```

Compiling from scratch:
```
# Install Node.js dependencies
npm install

# Aggregate Yaml specification files into a single swagger.json file
node resolve.js > swagger.json
```

After any of these steps you should have a complete `swagger.json` file, with specification of Onezone REST API. The file can be used by Swagger [code generator](https://github.com/swagger-api/swagger-codegen) to produce example code for clients in various languages or viewed online using for instance [Swagger Online Editor](http://editor.swagger.io/).

