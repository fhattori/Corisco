/* Depositor.java
 *
 * Copyright (c) 2007, Aberystwyth University
 *
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *  - Redistributions of source code must retain the above
 *    copyright notice, this list of conditions and the
 *    following disclaimer.
 *
 *  - Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution.
 *
 *  - Neither the name of the Centre for Advanced Software and
 *    Intelligent Systems (CASIS) nor the names of its
 *    contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
 * THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */
package org.dspace.sword;

import org.dspace.content.DSpaceObject;
import org.purl.sword.base.Deposit;
import org.purl.sword.base.SWORDErrorException;

/**
 * @author Richard Jones
 *
 * Abstract class for depositing content into the archive.
 */
public abstract class Depositor
{
	/**
	 * The sword service implementation
	 */
	protected SWORDService swordService;

	/**
	 * Construct a new Depositor with the given sword service on the given
	 * dspace object.  It is anticipated that extensions of this class will
	 * specialise in certain kinds of dspace object
	 *
	 * @param swordService
	 * @param dso
	 */
	public Depositor(SWORDService swordService, DSpaceObject dso)
	{
		this.swordService = swordService;
	}

	/**
	 * Execute the deposit process with the given sword deposit
	 *
	 * @param deposit
	 * @return
	 * @throws SWORDErrorException
	 * @throws DSpaceSWORDException
	 */
	public abstract DepositResult doDeposit(Deposit deposit) throws SWORDErrorException, DSpaceSWORDException;

	/**
	 * Undo any changes to the archive effected by the deposit
	 * 
	 * @param result
	 * @throws DSpaceSWORDException
	 */
	public abstract void undoDeposit(DepositResult result) throws DSpaceSWORDException;
}
