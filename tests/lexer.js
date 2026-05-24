#! echo ""

// single line comment
/*
    multi line comment
*/
const number = +23.09;
const negative_number = -23.09;
const hex = 0x1a;
const exponent_1 = 234e23;
const exponent_2 = 2.34e23;
const exponent_3 = 23.4e23;
const bytes = 0b0100111;
const bigint = 10n;
const infinity = Infinity;
const negative_infinity = -Infinity;
let object = { test_1: 1, [number]: 2 };
var string = "";
const array = [];
const null_value = null;
const undefined_value = undefined;

function call(args = "test", ...args) {
    return void array.push(null);
}

array[0];

call();

(((1 + 2) * 3) % 102 ** 3) / 2 - 10;

for (const value of array) {
    break;
}

for (const key in array) {
    array[key]?.toString();
    continue;
}

for (let i = 0; i < 1; i++) {
    --i;
    ++i;
}

(1 < 2,
    1 > 2,
    1 == 1,
    1 === 1,
    1 <= 2,
    1 >= 2,
    1 != 1,
    1 !== 1,
    !false,
    true && false,
    true || false,
    undefined ?? 1);

10 & 23;
12 ^ 2342;
32 | 42;
80 >> 2;
80 << 4;
32 >>> 8;
~8;

let test = 1;

test &= 23;
test ^= 2342;
test |= 42;
test >>= 2;
test <<= 4;
test >>>= 8;

if (false) {
} else if (false) {
} else {
}

while (false) {}

do {} while (false);
