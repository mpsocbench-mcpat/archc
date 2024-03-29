/**
 * @file      ac_tlm_port.H
 * @author    Thiago Massariolli Sigrist
 * 
 * @author    The ArchC Team
 *            http://www.archc.org/
 *
 *            Computer Systems Laboratory (LSC)
 *            IC-UNICAMP
 *            http://www.lsc.ic.unicamp.br/
 * 
 * @version   2.0alpha1
 * @date      Tue, 13 Dec 2005 20:08:46 -0200
 * 
 * @brief     Defines the ArchC TLM initiator port.
 * 
 * @attention Copyright (C) 2002-2005 --- The ArchC Team
 * 
 */

//////////////////////////////////////////////////////////////////////////////

#ifndef _AC_TLM_PORT_H_
#define _AC_TLM_PORT_H_

//////////////////////////////////////////////////////////////////////////////

// Standard includes
#include <string>

// SystemC includes
#include <systemc.h>

// ArchC includes
#include "ac_inout_if.H"
#include "ac_tlm_protocol.H"
#include "ac_tlm_dev_id.H"

//////////////////////////////////////////////////////////////////////////////

// using statements
using std::string;

//////////////////////////////////////////////////////////////////////////////

// Forward class declarations, needed to compile

//////////////////////////////////////////////////////////////////////////////

/// ArchC TLM initiator port class.
class ac_tlm_port : public sc_port<ac_tlm_transport_if>,
		    public ac_inout_if,
		    public ac_tlm_dev_id {
public:
  string name;
  uint32_t size;

  /** 
   * Default constructor.
   * 
   * @param name Port name.
   * @param size Size or address range of the element to be attached.
   * 
   */
  explicit ac_tlm_port(char const* name, uint32_t sz);

  /**
   * Default (virtual) destructor.
   * @return Nothing.
   */
  virtual ~ac_tlm_port();

  /** 
   * Reads a single word.
   * 
   * @param buf Buffer into which the word will be copied.
   * @param address Address from where the word will be read.
   * @param wordsize Word size in bits.
   * 
   */
  virtual void read(ac_ptr buf, uint32_t address,
		    int wordsize);

  /** 
   * Reads multiple words.
   * 
   * @param buf Buffer into which the words will be copied.
   * @param address Address from where the words will be read.
   * @param wordsize Word size in bits.
   * @param n_words Number of words to be read.
   * 
   */
  virtual void read(ac_ptr buf, uint32_t address,
		    int wordsize, int n_words);

  /** 
   * Writes a single word.
   * 
   * @param buf Buffer from which the word will be copied.
   * @param address Address to where the word will be written.
   * @param wordsize Word size in bits.
   *
   */
  virtual void write(ac_ptr buf, uint32_t address,
		     int wordsize);

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
		     int wordsize, int n_words);

  // Just for TLM2 support and compatibility

  void read(ac_ptr buf, uint32_t address,
  		      int wordsize,sc_core::sc_time &time_info) {

	  this->read(buf,address,wordsize);
  }

  void read(ac_ptr buf, uint32_t address,
  		      int wordsize, int n_words,sc_core::sc_time &time_info) {
	  this->read(buf,address,wordsize,n_words);
  }

  void write(ac_ptr buf, uint32_t address,
  		       int wordsize,sc_core::sc_time &time_info) {
  	this->write(buf,address,wordsize);
  }

  void write(ac_ptr buf, uint32_t address,
  		       int wordsize, int n_words,sc_core::sc_time &time_info) {

  	this->write(buf,address,wordsize,n_words);
  }




  virtual string get_name() const;

  virtual uint32_t get_size() const;

  /** 
   * Locks the device.
   * 
   */
   virtual void lock();

  /** 
   * Unlocks the device.
   * 
   */
   virtual void unlock();

};

//////////////////////////////////////////////////////////////////////////////

#endif // _AC_TLM_PORT_H_

