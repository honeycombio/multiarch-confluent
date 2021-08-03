# Multiarch Confluent Images

Confluent won't release arm64 images for their stuff because it "lacks
certification"; when pressed to support the dev env usecase on M1 Macs, they
suggest that it's just a jar, so ...

But I have a better idea.

A docker image is just a tarfile, right? And layers. So if all the layers after
the initial FROM are arch-agnostic, we should be able to use those layers atop
our own base image.

Now, we can't (AFAIK) do a multistage build, because our base layers will be
both x86 and arm64, and the confluent images are x86-only. That approach would
also require knowing which files specifically we want to copy over. But it's the
same idea in spirit.

# Notes
1. I'm using https://github.com/wagoodman/dive to poke at layers. (Ironically,
   this is only multiarch on Linux native, no multiarch docker image.)
  a. in cp-zookeeper:5.5.1, layer 0 is OS, 1 is netcat/less, 2 is etc/confluent,
3 is etc/confluent, 4 is actually installing zk and kafka, and 5 is etc/docker 
  b. in cp-kafka:5.5.1, pattern is basically the same - we care about layers 2-5
only.
  c. This is further supported by `docker inspect confluent/cp-{zookeeper,
kafka}:5.5.1 | jq '.[0].RootFS.Layers'`, which shows that layers 0-3 of these
two images are identical, while 4 and 5 differ.

2. If I can construct an image manifest by hand, I can use those layers on top
   of a known base image like ubuntu:18.04 or openjdk:18.
