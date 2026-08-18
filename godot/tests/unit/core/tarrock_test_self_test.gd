extends TarrockTest

## The test framework testing itself.
##
## Nothing here is allowed to be red. Where the point is "a broken assertion is
## recorded as a failure", we run the assertion on a NESTED `TarrockTest` and
## assert that the nested instance recorded it - so a genuinely failing assertion
## is proven without leaving a permanently failing test in the suite.

var _inner: TarrockTest = null


func before_each() -> void:
	_inner = TarrockTest.new()
	_inner._reset_failures()


func after_each() -> void:
	_inner = null


func test_passing_assertions_record_nothing() -> void:
	_inner.assert_true(true)
	_inner.assert_false(false)
	_inner.assert_eq(3, 3)
	_inner.assert_ne(3, 4)
	_inner.assert_null(null)
	_inner.assert_not_null(self)
	_inner.assert_almost_eq(0.1 + 0.2, 0.3, 0.0001)
	_inner.assert_has([1, 2, 3], 2)
	_inner.assert_has({"a": 1}, "a")
	assert_eq(_inner.failures().size(), 0, "passing assertions record no failures")


func test_failing_assertions_are_recorded() -> void:
	_inner.assert_true(false, "assert_true")
	assert_eq(_inner.failures().size(), 1, "assert_true(false) records one failure")
	_inner.assert_false(true, "assert_false")
	_inner.assert_eq(1, 2, "assert_eq")
	_inner.assert_ne(1, 1, "assert_ne")
	_inner.assert_null(1, "assert_null")
	_inner.assert_not_null(null, "assert_not_null")
	_inner.assert_almost_eq(1.0, 2.0, 0.001, "assert_almost_eq")
	_inner.assert_has([1, 2, 3], 9, "assert_has")
	assert_eq(_inner.failures().size(), 8, "every broken assertion recorded exactly one failure")


func test_assertions_record_and_continue() -> void:
	# Recording rather than aborting is the deliberate choice: one run reports
	# every broken expectation in a method, not just the first.
	_inner.assert_eq(1, 2, "first")
	_inner.assert_eq(3, 4, "second")
	assert_eq(_inner.failures().size(), 2, "a second failure after a first is still recorded")
	assert_has(_inner.failures()[0], "first")
	assert_has(_inner.failures()[1], "second")


func test_fail_records_its_message() -> void:
	_inner.fail("the sky is the wrong colour")
	assert_eq(_inner.failures().size(), 1)
	assert_has(_inner.failures()[0], "the sky is the wrong colour")


func test_failure_messages_carry_the_detail() -> void:
	_inner.assert_eq(1, 2, "counting")
	assert_has(_inner.failures()[0], "counting")
	assert_has(_inner.failures()[0], "expected 2, got 1")


func test_reset_failures_clears_the_record() -> void:
	_inner.fail("x")
	_inner._reset_failures()
	assert_eq(_inner.failures().size(), 0, "the runner's per-method reset clears failures")


func test_signal_watching_counts_emissions() -> void:
	var clock := GameClock.new()
	watch_signal(clock, &"second_ticked")
	clock.advance(2.5)
	assert_signal_emitted(clock, &"second_ticked", 2, "two whole seconds crossed")
	assert_eq(signal_arguments(clock, &"second_ticked", 0), [1])
	assert_eq(signal_arguments(clock, &"second_ticked", 1), [2])


func test_signal_not_emitted_is_a_failure() -> void:
	var clock := GameClock.new()
	_inner.watch_signal(clock, &"second_ticked")
	_inner.assert_signal_emitted(clock, &"second_ticked")
	assert_eq(_inner.failures().size(), 1, "a signal that never fired is a recorded failure")


func test_tree_is_reachable() -> void:
	assert_not_null(tree(), "tests can reach the SceneTree when they need real nodes")
