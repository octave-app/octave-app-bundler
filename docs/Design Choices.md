# Octave.app Design Choices

## Qt

### Qt versions

We'll build against the LTS Qt releases, since these are likely to be more stable and bug-fixed than the non-LTS Qt releases, and will receive updates for longer.

We want to avoid switching between minor versions of Qt for a given Octave version, but may still want to update to newer patch levels when a "u" update build comes out.
