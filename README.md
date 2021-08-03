# Disclaimer

This is _not_ officially supported by Honeycomb, nor has it been exhaustively
tested. We're just hoping to use it in our local dev environment.

# Multiarch Confluent Images

Confluent hasn't released arm64 images for their stuff because it "lacks
certification"; when pressed to support the dev env usecase on M1 Macs, they
suggest that it's just a jar, so why not build our own?

But I have a better idea.

A docker image is just a tarfile, right? And layers. So if all the layers after
the initial FROM are arch-agnostic, we should be able to use those layers atop
our own base image.

Now, we can't (AFAIK) do a multistage build, because our base layers will be
both x86 and arm64, and the confluent images are x86-only. That approach would
also require knowing which files specifically we want to copy over. But it's the
same idea in spirit.

So instead, `build.sh` gets the image whose contents we want, untars all but the
base layer and re-tars so they're merged (`tar --concatenate` is possibly buggy
for more than two files) and puts those in the new Docker image.

I'd intended to use `ADD newtar.tar.gz /` and let Docker take care of unzipping,
but ... that fails, presumably because the tarfile contains files that would
overwrite the existing files: `Error processing tar file(duplicates of file
paths not supported)`. (I don't _think_ `newtar.tar.gz` has any dupes itself.)

Finally, instead of doing a `RUN tar -xzvf ...` in the Dockerfile, I have a
`cmd` script that does that when the container is run. Because Github Actions
doesn't yet have ARM64 builders, we'll be doing cross-platform builds with QEMU,
and while that's fine for a build that is just a few `COPY`s, `RUN tar ...`
would be quite slow. By deferring that until the container starts, we get to run
tar on the correct architecture. It takes about 6s on my laptop to do that,
which seems like an acceptable startup cost.
