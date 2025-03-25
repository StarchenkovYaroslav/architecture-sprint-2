#!/bin/bash

###
# Инициализируем config server
###

docker compose exec -T configSvr mongosh --port 27017 <<EOF
rs.initiate(
  {
    _id : "config_server",
       configsvr: true,
    members: [
      { _id: 0, host: "configSvr:27017" }
    ]
  }
);
EOF

###
# Инициализируем shard1
###

docker compose exec -T shard1_repl1 mongosh --port 27018 <<EOF
rs.initiate(
    {
      _id : "shard1",
      members: [
        { _id: 0, host: "shard1_repl1:27018" },
        { _id: 1, host: "shard1_repl2:27019" },
        { _id: 2, host: "shard1_repl3:27020" },
      ]
    }
);
EOF

###
# Инициализируем shard2
###

docker compose exec -T shard2_repl1 mongosh --port 27021 <<EOF
rs.initiate(
    {
      _id: "shard2",
      members: [
       { _id: 0, host: "shard2_repl1:27021" },
       { _id: 1, host: "shard2_repl2:27022" },
       { _id: 2, host: "shard2_repl3:27023" },
      ]
    }
);
EOF

###
# Инициализируем mongos
###

docker compose exec -T mongos_router mongosh --port 27024 <<EOF

sh.addShard( "shard1/shard1_repl1:27018,shard1_repl2:27019,shard1_repl3:27020");
sh.addShard( "shard2/shard2_repl1:27021,shard2_repl2:27022,shard2_repl3:27023");

sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name": "hashed" } )

use somedb

for(var i = 0; i < 1000; i++) db.helloDoc.insert({age:i, name:"ly"+i})
EOF