## Testing external functions in contracts

Every contract or library `<Contract>` defined in `src/<subdir>/<FileName>.sol` should have a corresponding test `<Contract>Test` defined in `test/<subdir>/<FileName>.t.sol`.

Every execution path in the function should be tested, ideally with a distinct test. The naming should be `test_<functionName>_<PascalCaseLabel>`, where `PascalCaseLabel` is some brief summary of the path being tested.

Test case labels:
- For testing that a specific event is emitted that is not emitted in the default path, the label should be the name of the event.
- Same as above for testing that specific errors are thrown.
- If we're testing what happens when a null recipient is given in a transfer call, the label might be `test_transfer_NullRecipient`

## Library Tests

We use wrapper contracts for libraries in our tests for two reasons: forge coverage support and event/error testing.

Forge coverage issues:
1. Forge coverage is currently incapable of mapping MemberAccess function calls with expressions other than library identifiers, meaning expressions like `XLib.x(value)` will work in forge coverage, but expressions like `value.x()` will not.
2. Forge coverage will not track internal methods which are only invoked in the codebase within the context of a test function. This means that even if we wrote forge tests to directly access functions as library members (where the main codebase always uses them as members of a type), because the library method syntax is only used in the tests, those invocations will not cause the method to be tracked.

Events and errors:

- Forge's `expectEmit` and `expectRevert` operate on the next message call within the execution context, not the current call context. If a library has custom events or errors, we must invoke the methods which use them as external calls to validate they emit the right events or revert with the right errors.

Because of these issues, for any library in the main codebase which:
- has methods that are primarily invoked as type members rather than as standalone functions or library members; OR
- has methods which can emit events or revert; OR
- has methods which are not invoked in the main codebase

We define a wrapper library that redefines all the library functions as external functions, and a test contract which invokes those functions as external calls to the wrapper.
