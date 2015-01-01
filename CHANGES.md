1.4.1
-----
fix issue of scaling incorrectly when using decimals for example 
scale factor of 0.3 on a provisioned throuput of 1 would become 1 (using ciel)


1.4.0
-----

* add start_timer option to auto pilot and start in a future time

1.3.0
-----

* changed aws-sdk to v2 (aws-sdk-core)
* add local dynamodb support for testing
* refactor cli to its own module