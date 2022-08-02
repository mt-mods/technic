ARG ENGINE_VERSION=5.5.0
FROM registry.gitlab.com/minetest/minetest/server:${ENGINE_VERSION}

USER root
RUN apk add git &&\
    mkdir -p /root/.minetest/worlds/world/worldmods/ &&\
    cd /root/.minetest/worlds/world/worldmods/ &&\
    git clone --depth 1 https://github.com/BuckarooBanzay/mtt &&\
    git clone --recurse-submodules --depth 1 https://github.com/mt-mods/basic_materials.git &&\
    git clone --depth 1 https://github.com/mt-mods/pipeworks.git &&\
    git clone --depth 1 https://github.com/minetest-mods/moreores.git
