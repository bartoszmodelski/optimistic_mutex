(lang dune 3.7)

(name mutexlib)

(generate_opam_files true)

(source
 (github bartoszmodelski/mutexlib))

(authors "Bartosz Modelski")

(maintainers "Bartosz Modelski")

(license MIT)

(documentation https://url/to/documentation)

(package
 (name mutexlib)
 (synopsis "A short synopsis")
 (description "A longer description")
 (depends ocaml dune (alcotest :with-test) (cmdliner :with-test))
 (tags
  (topics "to describe" your project)))

