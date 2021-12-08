#!/usr/bin/env bash

# Doc generator from: https://github.com/pseudomuto/protoc-gen-doc
# NOTE - the docs builder will not create links to top-level protos
#           correctly.  To fix, the docs/index.html file is sed'd to
#           `s/href="#([A-Z])/href="#.$1/g`

set -e

#docker pull pseudomuto/protoc-gen-doc

TMP_DIR=build/tmp-docs-protos

function gen_doc() {
  docker run --rm -v "$(pwd)/docs":/out -v "$(pwd)"/${TMP_DIR}:/protos pseudomuto/protoc-gen-doc ${1} --doc_opt=/out/build/markdown.tmpl,${2}:validate/*
  sed -i '' -e "s|Protocol Documentation|${3}|" docs/${2}
  # Get rid of extraneous lines in TOC list that make format wonky
  sed -i '' -e '/^  $/d' docs/${2}
}

function gen_example() {
  (echo "Example:" && echo "\`\`\`json" && cat $1 && echo " " && echo "\`\`\`") > build/example.md
  sed -i '' '/INSERT_EXAMPLE/r build/example.md' $2
  sed -i '' 's/INSERT_EXAMPLE//' $2
}


mkdir -p ${TMP_DIR}
cp -r src/main/proto/* ${TMP_DIR}
cp -r docs/build/validate ${TMP_DIR}

gen_doc "tech/figure/asset/v1beta1/asset.proto" "asset.md" "Asset (NFT)"
gen_doc "tech/figure/loan/v1beta1/loan.proto" "loan.md" "Loan"
gen_doc "tech/figure/servicing/v1beta1/loan_state.proto" "servicing.md" "Loan Servicing"

pushd ${TMP_DIR}
FILE_LIST=$( find tech/figure/util -name "*.proto")
popd
gen_doc "${FILE_LIST}" "util.md" "Util"

sed -i '' -e 's/#tech.figure.util/util#tech.figure.util/g' docs/*.md

gen_example docs/build/examples/asset.json docs/asset.md
gen_example docs/build/examples/loan.json docs/loan.md


