/**
 * @file      ac_inout_tlm2_if.H
 * @author    Liana Duenha
 *
 *            The ArchC Team
 *            http://www.archc.org/
 *
 *            Computer Systems Laboratory (LSC)
 *            IC-UNICAMP
 *            http://www.lsc.ic.unicamp.br/
 *
 *
 */

//////////////////////////////////////////////////////////////////////////////

#ifndef _AC_INOUT_TLM2_IF_H_
#define _AC_INOUT_TLM2_IF_H_

//////////////////////////////////////////////////////////////////////////////

// Standard includes
#include <stdint.h>
#include <string>

// SystemC includes
#include <systemc.h>


// ArchC includes
#include "ac_ptr.H"

//////////////////////////////////////////////////////////////////////////////

// 'using' statements

//////////////////////////////////////////////////////////////////////////////

// Forward class declarations, needed to compile

//////////////////////////////////////////////////////////////////////////////

/// ac_inout_tlm2_if is a simple interface that contains read, write and lock
/// methods, with support time information as a parameter.


class ac_inout_tlm2_if {
public:

  /** 
   * Reads a single word.
   * 
   * @param buf Buffer into which the word will be copied.
   * @param address Address from where the word will be read.
   * @param wordsize Word size in bits.
   * 
   */
   virtual void read(ac_ptr buf, uint32_t address,int wordsize,sc_core::sc_time &time_info) = 0;

  /** 
   * Reads multiple words.
   * 
   * @param buf Buffer into which the words will be copied.
   * @param address Address from where the words will be read.
   * @param wordsize Word size in bits.
   * @param n_words Number of words to be read.
   * 
   */

  // = sc_core::sc_time(0,SC_NS)
  virtual void read(ac_ptr buf, uint32_t address,int wordsize, int n_words,sc_core::sc_time &time_info) = 0;

  /** 
   * Writes a single word.
   * 
   * @param buf Buffer from which the word will be copied.
   * @param address Address to where the word will be written.
   * @param wordsize Word size in bits.
   *
   */
  virtual void write(ac_ptr buf, uint32_t address,
		     int wordsize,sc_core::sc_time& time_info) = 0;

  /** 
   * Writes multiple words.
   * 
   * @param buf Buffer from which the words will be copied.
   * @param address Address to where the words will be written.
   * @param wordsize Word size in bits.
   * @param n_words Number of words to be written.
   * 
   */
  virtual void write(ac_ptr buf, uint32_t address,
		     int wordsize, int n_words,sc_core::sc_time &time_info) = 0;

  virtual std::string get_name() const = 0;

  virtual uint32_t get_size() const = 0;

  /** 
   * Locks the device.
   * 
   */
   virtual void lock() = 0;

  /** 
   * Unlocks the device.
   * 
   */
   virtual void unlock() = 0;

};



#endif // _AC_INOUT_TLM2_IF_H_
