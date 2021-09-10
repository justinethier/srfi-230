extern object quote_sequentially_91consistent;
extern object quote_acquire_91release;
extern object quote_release;
extern object quote_acquire;
extern object quote_relaxed;

memory_order scm2c_memord(object mo) {
  if (mo == quote_acquire_91release) {
     return memory_order_acq_rel;
  } else if (mo == quote_release) {
            return memory_order_release;
  } else if (mo == quote_acquire) {
            return memory_order_acquire;
  } else if (mo == quote_relaxed) {
            return memory_order_relaxed;
  } else {
            return memory_order_seq_cst;
  }
}
