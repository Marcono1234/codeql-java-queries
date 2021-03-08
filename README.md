# codeql-java-queries
Personal [CodeQL](https://securitylab.github.com/tools/codeql) queries for Java source code.
Unlike the [standard CodeQL queries](https://codeql.github.com/codeql-query-help/java/) which
mostly focus on security, the queries of this repository are mostly for general bug patterns
and code style recommendations which are not necessarily security related.

:warning: This repository currently mainly acts as scratchpad; query implementations might not
follow best practices, might be ineffecient, might yield a lot of false positives and are not
properly documented and tested.  
This repository is therefore not recommended if you want to learn CodeQL; instead have a look
at the [CodeQL documentation](https://codeql.github.com/docs/) and the [CodeQL repository](https://github.com/github/codeql).

## Running the queries
Most or all queries can directly be run in the [LGTM Query Console](https://lgtm.com/query/lang:java/)
or from within the [Visual Studio Code extension](https://codeql.github.com/docs/codeql-for-visual-studio-code/).

Please be aware that, as with all code scanning tools, results might be false positives.
Carefully examine all findings and don't blindly follow the given advice.

## License
The code in this project is licensed under the [MIT License](./LICENSE.txt). Some queries
are based on bug patterns detected by other code scanning applications, or described by
advisories such as the Common Weakness Enumeration. Please let me know if you think
any of the code infringes your rights.

Please note however, that usage of CodeQL itself has to adhere to the [GitHub CodeQL Terms and Conditions](https://securitylab.github.com/tools/codeql/license).

Feel free to port queries contained in this repository to other code scanning application
(with the disclaimer in mind that some of the queries are based on bug patterns detected
by other applications). In case a query covers a bug pattern not yet detected by any
other application or mentioned in any advisory, I would be pleased about any credits.

## Contributing
The direction in which this repository is heading is currently not clear, I might
therefore be reluctant to accepting any new query submissions. Though improvements
of existing queries (except for complete rewrites) are welcome.

All contributions are implicitly made under the [license of this project](./LICENSE.txt).

In general please prefer directly contributing to the [CodeQL repository](https://github.com/github/codeql).
