module eventcore.internal.utils;

import taggedalgebraic;


void print(ARGS...)(string str, ARGS args)
@trusted @nogc nothrow {
	import std.format : formattedWrite;
	StdoutRange r;
	scope cb = () {
		scope (failure) assert(false);
		(&r).formattedWrite(str, args);
	};
	(cast(void delegate() @nogc @safe nothrow)cb)();
	r.put('\n');
}

private extern(C) Throwable.TraceInfo _d_traceContext(void* ptr = null);

void nogc_assert(bool cond, string message, string file = __FILE__, int line = __LINE__)
@trusted nothrow {
	import core.stdc.stdlib : abort;
	import std.stdio : stderr;

	if (!cond) {
		scope (exit) {
			abort();
			assert(false);
		}

		stderr.writefln("Assertion failure @%s(%s): %s", file, line, message);
		stderr.writeln("------------------------");
		if (auto info = _d_traceContext(null)) {
			foreach (s; info)
				stderr.writeln(s);
		} else stderr.writeln("no stack trace available");
	}
}

struct StdoutRange {
	@safe: @nogc: nothrow:
	import core.stdc.stdio;

	void put(string str)
	{
		() @trusted { fwrite(str.ptr, str.length, 1, stdout); } ();
	}

	void put(char ch)
	{
		() @trusted { fputc(ch, stdout); } ();
	}
}

struct ChoppedVector(T, size_t CHUNK_SIZE = 16*64*1024/nextPOT(T.sizeof)) {
	import core.memory : GC;

	static assert(nextPOT(CHUNK_SIZE) == CHUNK_SIZE,
		"CHUNK_SIZE must be a power of two for performance reasons.");

	@safe: nothrow:
	import core.stdc.stdlib : calloc, free, malloc, realloc;
	import std.traits : hasIndirections;

	alias chunkSize = CHUNK_SIZE;

	private {
		alias Chunk = T[chunkSize];
		alias ChunkPtr = Chunk*;
		ChunkPtr[] m_chunks;
		size_t m_chunkCount;
		size_t m_length;
	}

	@disable this(this);

	~this()
	@nogc {
		clear();
	}

	@property size_t length() const @nogc { return m_length; }

	void clear()
	@nogc {
		() @trusted {
			foreach (i; 0 .. m_chunkCount) {
				destroy(m_chunks[i]);
				static if (hasIndirections!T)
					GC.removeRange(m_chunks[i]);
				free(m_chunks[i]);
			}
			free(m_chunks.ptr);
		} ();
		m_chunkCount = 0;
		m_length = 0;
	}

	ref T opIndex(size_t index)
	@nogc {
		auto chunk = index / chunkSize;
		auto subidx = index % chunkSize;
		if (index >= m_length) m_length = index+1;
		reserveChunk(chunk);
		return (*m_chunks[chunk])[subidx];
	}

	int opApply(scope int delegate(size_t idx, ref T) @safe nothrow del)
	{
		size_t idx = 0;
		foreach (c; m_chunks) {
			if (c) {
				foreach (i, ref t; *c)
					if (auto ret = del(idx+i, t))
						return ret;
			}
			idx += chunkSize;
		}
		return 0;
	}

	int opApply(scope int delegate(size_t idx, ref const(T)) @safe nothrow del)
	const {
		size_t idx = 0;
		foreach (c; m_chunks) {
			if (c) {
				foreach (i, ref t; *c)
					if (auto ret = del(idx+i, t))
						return ret;
			}
			idx += chunkSize;
		}
		return 0;
	}

	private void reserveChunk(size_t chunkidx)
	@nogc {
		if (m_chunks.length <= chunkidx) {
			auto l = m_chunks.length == 0 ? 64 : m_chunks.length;
			while (l <= chunkidx) l *= 2;
			() @trusted {
				auto newptr = cast(ChunkPtr*)realloc(m_chunks.ptr, l * ChunkPtr.length);
				assert(newptr !is null, "Failed to allocate chunk index!");
				m_chunks = newptr[0 .. l];
			} ();
		}

		while (m_chunkCount <= chunkidx) {
			() @trusted {
				auto ptr = cast(ChunkPtr)calloc(chunkSize, T.sizeof);
				assert(ptr !is null, "Failed to allocate chunk!");
				// FIXME: initialize with T.init instead of 0
				static if (hasIndirections!T)
					GC.addRange(ptr, chunkSize * T.sizeof);
				m_chunks[m_chunkCount++] = ptr;
			} ();
		}
	}
}

struct AlgebraicChoppedVector(TCommon, TSpecific...)
{
	import std.conv : to;
	import std.meta : AliasSeq;

	union U {
		typeof(null) none;
		mixin fields!0;
	}
	alias FieldType = TaggedAlgebraic!U;
	static struct FullField {
		TCommon common;
		FieldType specific;
		mixin(accessors());
	}

	ChoppedVector!(FullField) items;

	alias items this;

	private static string accessors()
	{
		import std.format : format;
		string ret;
		foreach (i, U; TSpecific)
			ret ~= "@property ref TSpecific[%s] %s() nothrow @safe { return this.specific.get!(TSpecific[%s]); }\n"
				.format(i, U.Handle.name, i);
		return ret;
	}

	private mixin template fields(size_t i) {
		static if (i < TSpecific.length) {
			mixin("TSpecific["~i.to!string~"] "~TSpecific[i].Handle.name~";");
			mixin fields!(i+1);
		}
	}
}



/** Efficient bit set of dynamic size.
*/
struct SmallIntegerSet(V : size_t)
{
	private {
		uint[][4] m_bits;
		size_t m_count;
	}

	@property bool empty() const { return m_count == 0; }

	void insert(V i)
	{
		foreach (j; 0 .. m_bits.length) {
			uint b = 1u << (i%32);
			i /= 32;
			if (i >= m_bits[j].length)
				m_bits[j].length = nextPOT(i+1);
			if (j == 0 && !(m_bits[j][i] & b)) m_count++;
			m_bits[j][i] |= b;
		}
	}

	void remove(V i)
	{
		foreach (j; 0 .. m_bits.length) {
			uint b = 1u << (i%32);
			i /= 32;
			if (!m_bits[j][i]) break;
			if (j == 0 && m_bits[j][i] & b) m_count--;
			m_bits[j][i] &= ~b;
			if (m_bits[j][i]) break;
		}
	}

	bool contains(V i) const { return i/32 < m_bits[0].length && m_bits[0][i/32] & (1u<<(i%32)); }

	int opApply(scope int delegate(V) @safe nothrow del)
	const @safe {
		int rec(size_t depth, uint bi)
		{
			auto b = m_bits[depth][bi];
			foreach (i; 0 .. 32)
				if (b & (1u << i)) {
					uint sbi = bi*32 + i;
					if (depth == 0) {
						if (auto ret = del(V(sbi)))
							return ret;
					} else rec(depth-1, sbi);
				}
			return 0;
		}

		foreach (i, b; m_bits[$-1])
			if (b) {
				if (auto ret = rec(m_bits.length-1, cast(uint)i))
					return ret;
			}

		return 0;
	}
}

unittest {
	uint[] ints = [0, 16, 31, 128, 4096, 65536];

	SmallIntegerSet!uint set;
	bool[uint] controlset;

	assert(set.empty);
	foreach (i; ints) {
		set.insert(i);
		controlset[i] = true;
	}
	assert(!set.empty);

	foreach (jidx, j; ints) {
		size_t cnt = 0;
		bool[int] seen;
		foreach (i; set) {
			assert(i in controlset);
			assert(i !in seen);
			seen[i] = true;
			cnt++;
		}
		assert(cnt == ints.length - jidx);

		set.remove(j);
		controlset.remove(j);
	}
	assert(set.empty);

	foreach (i; set) assert(false);
}

@safe nothrow unittest {
	SmallIntegerSet!uint s;

	void testIter(scope uint[] seq...) nothrow {
		size_t cnt = 0;
		foreach (v; s) {
			assert(v == seq[cnt]);
			cnt++;
		}
		assert(cnt == seq.length);
	}

	testIter();
	s.insert(1);
	assert(s.contains(1));
	assert(!s.contains(2));
	testIter(1);
	s.insert(3467);
	assert(s.contains(3467));
	assert(!s.contains(300));
	testIter(1, 3467);
	s.insert(2);
	testIter(1, 2, 3467);
	s.remove(1);
	testIter(2, 3467);
	s.remove(2);
	testIter(3467);
	s.remove(3467);
	testIter();
}

private size_t nextPOT(size_t n) @safe nothrow @nogc
{
	foreach_reverse (i; 0 .. size_t.sizeof*8) {
		size_t ni = cast(size_t)1 << i;
		if (n & ni) {
			return n & (ni-1) ? ni << 1 : ni;
		}
	}
	return 1;
}

unittest {
	assert(nextPOT(1) == 1);
	assert(nextPOT(2) == 2);
	assert(nextPOT(3) == 4);
	assert(nextPOT(4) == 4);
	assert(nextPOT(5) == 8);
}
