typedef enum bit [1:0] {
  UART_PARITY_NONE,
  UART_PARITY_EVEN,
  UART_PARITY_ODD
} uart_parity_e;

class uart_configuration extends uvm_object;
  rand uart_parity_e parity_mode = UART_PARITY_NONE;
  rand int unsigned data_width = 8;
  rand int unsigned num_of_stop_bit = 1;
  rand int unsigned baud_rate = 115200;
  // Zero selects baud_rate; a positive value selects the exact actual period.
  // Set only between frames, on both TX and RX.
  realtime configured_bit_period = 0.0;
  real baud_tolerance = 0.02;
  uvm_active_passive_enum is_active = UVM_ACTIVE;
  virtual uart_if vif;
  // Test-controlled reset coordination; preserve the original two-wire interface.
  // Update this alongside DUT reset. Driver/monitor read the live configuration.
  bit reset_n = 1'b1;

  constraint legal_frame_c {
    parity_mode inside {UART_PARITY_NONE, UART_PARITY_EVEN, UART_PARITY_ODD};
    data_width inside {[5:8]};
    num_of_stop_bit inside {[1:2]};
    baud_rate > 0;
    soft baud_rate inside {4800, 9600, 19200, 57600, 115200};
  }

  `uvm_object_utils_begin(uart_configuration)
    `uvm_field_enum(uart_parity_e, parity_mode, UVM_ALL_ON)
    `uvm_field_int(data_width, UVM_ALL_ON)
    `uvm_field_int(num_of_stop_bit, UVM_ALL_ON)
    `uvm_field_int(baud_rate, UVM_ALL_ON)
    `uvm_field_real(configured_bit_period, UVM_ALL_ON)
    `uvm_field_real(baud_tolerance, UVM_ALL_ON)
    `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "uart_configuration");
    super.new(name);
  endfunction

  function bit is_valid();
    return (parity_mode inside {
             UART_PARITY_NONE, UART_PARITY_EVEN, UART_PARITY_ODD
           }) &&
           (data_width inside {[5:8]}) &&
           (num_of_stop_bit inside {[1:2]}) &&
           (baud_rate > 0) &&
           (configured_bit_period >= 0.0) &&
           (bit_period() >= 2ps) &&
           (is_active inside {UVM_ACTIVE, UVM_PASSIVE}) &&
           (baud_tolerance >= 0.0 && baud_tolerance <= 0.1);
  endfunction

  // Frequency-based setter avoids caller time-unit conversion issues.
  function void set_baud_rate(real rate_hz);
    if (!(rate_hz > 0.0)) `uvm_fatal("UART_BAUD", "Baud rate must be positive")
    set_bit_period(1s / rate_hz);
  endfunction

  // The argument is in this package's time unit (ns).
  function void set_bit_period(realtime period);
    if (period < 2ps) `uvm_fatal("UART_PERIOD", "Bit period must be at least 2ps")
    configured_bit_period = period;
  endfunction

  function realtime bit_period();
    return configured_bit_period > 0.0 ? configured_bit_period : 1s / real'(baud_rate);
  endfunction
endclass
