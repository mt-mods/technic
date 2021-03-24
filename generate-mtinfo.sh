#!/bin/sh

# prepare config
CONFIG=/tmp/technic_minetest.conf
echo "mtinfo.autoshutdown = true" > ${CONFIG}

# prepare dependent mods
WORLDMODS_DIR=/tmp/technic_worldmods
git clone --depth=1 https://gitlab.com/VanessaE/basic_materials.git ${WORLDMODS_DIR}/basic_materials
git clone --depth=1 https://gitlab.com/VanessaE/pipeworks.git ${WORLDMODS_DIR}/pipeworks
git clone --depth=1 https://gitlab.com/VanessaE/unifieddyes.git ${WORLDMODS_DIR}/unifieddyes
git clone --depth=1 https://github.com/minetest-mods/moreblocks.git ${WORLDMODS_DIR}/moreblocks
git clone --depth=1 https://github.com/BuckarooBanzay/mtinfo.git ${WORLDMODS_DIR}/mtinfo
cp . ${WORLDMODS_DIR}/technic -R

# start container with mtinfo
docker run --rm -i \
	--user root \
	-v ${CONFIG}:/etc/minetest/minetest.conf:ro \
  -v ${WORLDMODS_DIR}/:/root/.minetest/worlds/world/worldmods \
	-v $(pwd)/output:/root/.minetest/worlds/world/mtinfo \
	registry.gitlab.com/minetest/minetest/server:5.3.0

test -f $(pwd)/output/index.html || exit 1
test -f $(pwd)/output/data/items.js || exit 1
test -d $(pwd)/output/textures || exit 1
