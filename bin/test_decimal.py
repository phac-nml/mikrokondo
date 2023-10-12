from timeit import Timer
from statistics import mean, fmean
import decimal
import random
from tqdm import tqdm
import itertools
import gc
import array

random.seed(42)

RAND_LIST = [random.randint(0, 34) for _ in range(100)]
INT_ARRAY = array.array("l", RAND_LIST)
DECIMAL = [decimal.Decimal(i) for i in RAND_LIST]
FLOAT = [float(i) for i in RAND_LIST]


class ProgressTimer(Timer):
    """Stack overflow: https://stackoverflow.com/questions/70968477/show-timeit-progress

    Args:
        Timer (_type_): _description_
    """

    def timeit(self, number):
        """Time 'number' executions of the main statement.
        To be precise, this executes the setup statement once, and
        then returns the time it takes to execute the main statement
        a number of times, as a float measured in seconds.  The
        argument is the number of times through the loop, defaulting
        to one million.  The main statement, the setup statement and
        the timer function to be used are passed to the constructor.
        """
        # wrap the iterator in tqdm
        it = tqdm(itertools.repeat(None, number), total=number)
        gcold = gc.isenabled()
        gc.disable()
        try:
            timing = self.inner(it, self.timer)
        finally:
            if gcold:
                gc.enable()
        # the tqdm bar sometimes doesn't flush on short timers, so print an empty line
        print()
        return timing

def mean_c(nums, func):
    def _mean_c():
        func(nums)
    return _mean_c

iters = 10000000
d = ProgressTimer(mean_c(DECIMAL, mean))
i = ProgressTimer(mean_c(RAND_LIST, mean))
f = ProgressTimer(mean_c(FLOAT, mean))
ff =ProgressTimer(mean_c(FLOAT, fmean))
fi =ProgressTimer(mean_c(INT_ARRAY, fmean))
print("Float Fmean: ", ff.timeit(iters))
print("Int array Fmean: ", fi.timeit(iters))
print("Decimal: ", d.timeit(iters))
print("Integer: ", i.timeit(iters))
print("Float: ", f.timeit(iters))

