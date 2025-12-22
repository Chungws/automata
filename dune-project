(lang dune 3.0)

(name automata)

(generate_opam_files true)

(source
 (github dapi/automata))

(authors "dapi")

(maintainers "dapi")

(license MIT)

(package
 (name automata)
 (synopsis "Automata theory implementations in OCaml")
 (description "A project-based learning repository for automata theory")
 (depends
  (ocaml (>= 4.14))
  dune
  (alcotest :with-test)))
