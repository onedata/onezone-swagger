#!/bin/bash

# Generate aggregate JSON file from YAML
docker run --rm -e "CHOWNUID=${UID}" -v `pwd`:/swagger docker.onedata.org/swagger-aggregator:1.5.0

# Validate the JSON
output=$(docker run --rm -e "CHOWNUID=${UID}" -v `pwd`:/swagger docker.onedata.org/swagger-cli:1.5.0 validate /swagger/swagger.json 2>&1)

if [[ $output =~ .*Swagger\ schema\ validation\ failed.* ]]; then
  echo "Generated swagger.json is not valid - check YAML sources:\n"
  echo $output
  exit 1
fi

# Generate the Cowboy server stub
docker run --rm -e "CHOWNUID=${UID}" -v `pwd`:/swagger -t docker.onedata.org/swagger-codegen:1.5.3 generate -i ./swagger.json -l cowboy -o ./generated/cowboy

# Fix generated Erlang files
./fix_generated.py

# Generate C# stub to get all moustache tempalte keywords
#swagger-codegen-dbg generate -i ./swagger.json -l csharp -o ./generated/csharp -o tmp > model.json

# Generate the static documentation
docker run --rm -e "CHOWNUID=${UID}" -v `pwd`:/swagger -t docker.onedata.org/swagger-bootprint:1.5.0 swagger ./swagger.json generated/static

#cp generated/static/index.html generated/static/onezone-static.html
sed -n '/<body>/,/<\/body>/p' generated/static/index.html \
  | sed -e '1s/.*<body>//' -e '$s/<\/body>.*//' -e 's/\/definitions\//definitions--/g' -e 's/<div class=\"container\"/<div class=\"container swagger\"/' \
  > generated/static/onezone-static.html

# Generate Markdown for direct Gitbook integration
# The output from generated/gitbook should be copied to onedata-documentation/doc/advanced/rest/onezone folder
docker run --rm -v `pwd`:/swagger -t docker.onedata.org/swagger-gitbook:1.4.1 convert -i ./swagger.json -d ./generated/gitbook -c ./gitbook.properties