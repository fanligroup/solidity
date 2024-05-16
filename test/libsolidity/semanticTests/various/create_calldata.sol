contract C {
	bytes public s;
	constructor(uint256 x) {
		// Due to a bug in EVMHost, msg.data used to contain initcode and constructor arguments.
		s = msg.data;
		assert(msg.data.length == 0);
	}
}
// ----
// constructor(): 42 ->
// gas irOptimized: 68239
// gas irOptimized code: 69000
// gas legacy: 78076
// gas legacy code: 90200
// gas legacyOptimized: 68369
// gas legacyOptimized code: 65200
// s() -> 0x20, 0
