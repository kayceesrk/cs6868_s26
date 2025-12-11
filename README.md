# CS3100: Paradigms of Programming (IITM Monsoon 2025)

This is the Github repo for the course CS3100 Paradigms of Programming taught at
IITM in the Monsoon semester 2025. The course website is here:
https://kcsrk.info/cs3100_m25/.

The course teaches OCaml and Prolog.

The first part of the course covers OCaml. The course covers a significant chunk
of the OCaml language. You should be able to self-study the course to get a good
understanding of the language. That said, the course deliberately does not cover
the build system (dune), package manager (opam), command-line tools for the
compiler (ocamlc, ocamlopt), editor integration (merlin, ocaml-lsp,
ocamlformat), etc. If you are keen to learn these, please refer to the excellent
[ocaml.org](https://ocaml.org/) website. In addition, the course does not cover
the use of OCaml libraries. Hence, the course is not meant to make you a
"productive" OCaml programmer building real-world applications. For this, I
recommend [Real World OCaml](https://dev.realworldocaml.org/).

The second part of the course covers Prolog. The course gives a good
introduction to Prolog, but does not go beyond the basics.

## Running the JupyterLab environment

Install [docker](https://docs.docker.com/install/#supported-platforms) for your
platform. The Docker image includes JupyterLab with OCaml and SWI-Prolog kernels,
plus RISE extension for presentations. Then run

```bash
git clone https://github.com/kayceesrk/cs3100_m25
cd cs3100_m25
docker run -it -p 8888:8888 -v "$(pwd)":/cs3100_iitm kayceesrk/cs3100_iitm:m25
```

Copy and paste the displayed URL that starts with `http://127.0.0.1:8888` into
your browser to access JupyterLab. If you save the changes to the notebooks,
they are saved locally.  The environment includes presentation mode (RISE) -
look for the presentation button in the toolbar.  As you go through the course,
you will have to do `git pull` in the `cs3100_m25` directory to get the latest
updates from upstream.

## Tips

For navigating the notebooks in presentation mode, only stick to

* `space` -- move forward
* `shift+space` -- move backward
* `cmd+enter` -- execute cell

Anything else, such as the arrow keys, `shift+enter`, etc, will lead to [unintuitive behaviour](https://rise.readthedocs.io/en/latest/usage.html#navigation).

Limited editor support is available for OCaml.

* `tab` -- code completion
* `shift+tab` -- inspection

See https://ocaml.org/p/jupyter/latest#code-completion.
