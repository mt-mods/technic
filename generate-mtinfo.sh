#!/bin/sh

# prepare config
CONFIG=/tmp/technic_minetest.conf
echo "mtinfo.enabled = true" > ${CONFIG}
echo "mtinfo.autoshutdown = true" >> ${CONFIG}
echo "moreblocks.stairsplus_in_creative_inventory = false" >> ${CONFIG}

# prepare dependent mods
WORLDMODS_DIR=/tmp/technic_worldmods
git clone --recurse-submodules --depth=1 https://github.com/mt-mods/basic_materials.git ${WORLDMODS_DIR}/basic_materials
git clone --depth=1 https://github.com/mt-mods/pipeworks.git ${WORLDMODS_DIR}/pipeworks
git clone --depth=1 https://github.com/mt-mods/unifieddyes.git ${WORLDMODS_DIR}/unifieddyes
git clone --depth=1 https://github.com/minetest-mods/moreblocks.git ${WORLDMODS_DIR}/moreblocks
git clone --depth 1 https://github.com/minetest-mods/moreores.git ${WORLDMODS_DIR}/moreores
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
