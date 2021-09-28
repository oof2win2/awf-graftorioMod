# graftorio

visualize metrics from your factorio game in grafana

![](https://mods-data.factorio.com/assets/89653f5de75cdb227b5140805d632faf41459eee.png)

## What is this?

[grafana](https://grafana.com/) is an open-source project for rendering time-series metrics. by using graftorio, you can create a dashboard with various charts monitoring aspects of your factorio factory. this dashboard is viewed using a web browser outside of the game client. (works great in a 2nd monitor!)

in order to use graftorio, you need to run the grafana software and a database called [prometheus](https://prometheus.io/) locally. graftorio automates this process using docker, or you can set these up by hand.

This can be used for factorio running on a server or a local instance. Since it will always export it to `{factorio-path}/script-output/game.prom`
