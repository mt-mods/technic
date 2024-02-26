ARG ENGINE_IMAGE=ghcr.io/minetest-hosting/minetest-docker:5.8.0

FROM ${ENGINE_IMAGE}
ARG MTG_VERSION=master
USER root
RUN apk add git &&\
    mkdir -p /root/.minetest/worlds/world/worldmods/ &&\
    cd /root/.minetest/worlds/world/worldmods/ &&\
    git clone --depth 1 https://github.com/BuckarooBanzay/mtt &&\
    git clone --recurse-submodules --depth 1 https://github.com/mt-mods/basic_materials.git &&\
    git clone --depth 1 https://github.com/mt-mods/pipeworks.git &&\
    git clone --depth 1 https://github.com/minetest-mods/moreores.git &&\
    git clone --depth 1 https://github.com/mt-mods/xcompat.git &&\
    mkdir /root/.minetest/games &&\
    git clone https://github.com/minetest/minetest_game.git /root/.minetest/games/minetest &&\
    cd /root/.minetest/games/minetest &&\
    git checkout ${MTG_VERSION}
