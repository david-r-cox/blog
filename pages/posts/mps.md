---
title: 'MPS: From Punch Cards to Rust'
date: 2024/01/09
tags: ['optimization', 'parsing', 'rust']
description: The venerable MPS optimization file format has its share of odd conventions and limitations inherited from its 1960s punch card origins.
---

The [Mathematical Programming System (MPS)](https://en.wikipedia.org/wiki/MPS_(format)) file format dates back to the 1960s era of [punched cards](https://en.wikipedia.org/wiki/Punched_card) and mainframes, but lives on as a way to represent optimization problems. MPS comes with its share of quirks that make it an interesting format to parse. In this post, we'll explore some techniques for robustly handling these legacy format eccentricities.

## The MPS Format

At a high level, MPS consists of several sections defining variables, constraints, objectives etc. But beyond that basic framing lie some curveballs:

- **Blank vs Apostrophe Delimited Names:** Names can be delimited by apostrophes or just blanks
- **Unused Sections:** Sections can be omitted entirely if unused
- **Column Orientation:** Fundamentally column-oriented, unlike modern row-based formats
- **No Native Quadratics:** Quadratic terms need external translation

One of the better references for the format is within the documentation for [`lp_solve`](https://lpsolve.sourceforge.net/5.5/) and [is worth reading](https://lpsolve.sourceforge.net/5.5/mps-format.htm) if you're working with the format.

## Introducing mps

The [`mps`](https://lib.rs/crates/mps) is a parser combinator library aims to be performant and ease the process of working with MPS files in Rust. In addition to its library interface, `mps` offers a CLI, integration testing via [proptest](https://lib.rs/crates/proptest) and snapshot testing with [insta](https://lib.rs/crates/insta).

```rust
use mps::Parser;

let data = "
NAME example
ROWS
 N  OBJ
 L  R1
 L  R2
 E  R3
COLUMNS
    X1        OBJ       -6
    X1        R1        2
    X1        R2        1
    X1        R3        3
    X2        OBJ       7
    X2        R1        5
    X2        R2        -1
    X2        R3        2
    X3        OBJ       4
    X3        R1        -1
    X3        R2        -2
    X3        R3        2
RHS
    RHS1      R1        18
    RHS1      R2        -14
    RHS1      R3        26
BOUNDS
 LO BND1      X1        0
 LO BND1      X2        0
 LO BND1      X3        0
ENDATA";

cfg_if::cfg_if! {
  if #[cfg(feature = "located")] {
    use nom_locate::LocatedSpan;
    use nom_tracable::TracableInfo;
    let info = TracableInfo::new().forward(true).backward(true);
    Parser::<f32>::parse(LocatedSpan::new_extra(data, info));
  } else {
    Parser::<f32>::parse(data);
  }
}
```

## Try It!

`mps` is not yet stable. Feel welcome to give it a spin anyway with:

Cargo:
```bash
cargo install mps
```

Docker:
```bash
docker run -it integratedreasoning/mps
```

or Nix:

```nix
{
  inputs.mps.url = "https://flakehub.com/f/integrated-reasoning/mps/*.tar.gz";

  outputs = { self, mps }: {
    # Use in your outputs
  };
}
```

MPS files may seem like relics, but with Rust we can handle their legacy quirks and make parsing them feel modern. I'm excited to keep extending the functionality of `mps` using the robustness and performance that Rust offers.
