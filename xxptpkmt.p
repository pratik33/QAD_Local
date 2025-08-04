/* xxpkptmt.p - - Pack Qty Udate                                                         */
/* Copyright 1986-2002 QAD Inc., Carpinteria, CA, USA.                                   */
/* All rights reserved worldwide.  This is an unpublished work.                          */
/* REVISION: EE2013                                                                      */
/* CREATED BY  : C'shekhar	DATE : 25/08/2015	               ECO : CLD20150825 */ 
/* MODIFIED BY : C'shekhar      DATE : 06/06/2019                      ECO : CLD20190606 */
/* MODIFIED BY : C'shekhar      DATE : 25/09/2020                      ECO : CLD20200925 */
/*****************************************************************************************/
{us/mf/mfdtitle.i}

define variable l_part         like pt_part init "" no-undo.
define variable l_site         like pt_site init "" no-undo. /* CLD20190606 */
define variable l_boxq         like pt_ord_mult     no-undo.
define variable l_s_boxq       like pt_ord_mult  LABEL "Site Qty" no-undo.
define variable l_shpwt        like pt_ship_wt      no-undo.
define variable l_netwt        like pt_net_wt       no-undo.
/*define variable l_ok           as   logical         no-undo. CLD20200925 */

form 
    l_part      colon 20
    l_site      colon 20	/* CLD20190606 */
    pt_desc1	colon 20
    pt_desc2 	colon 20
    l_boxq	colon 20
    l_s_boxq    colon 50 	/* CLD20190606 */
    l_shpwt	colon 20
    l_netwt	colon 50
/*    l_ok	colon 20 label "Ok" CLD20200925 */ 
    with frame fmframe centered side-labels width 80.

setframelabels(frame fmframe:handle).

mainloop:
Repeat:
	
	/* assign l_ok = no. CLD20200925 */
	update
	       l_part 
               l_site VALIDATE( (input l_site <> "" ) AND 
                                ( CAN-FIND ( FIRST si_mstr WHERE si_domain = global_domain AND si_site = input l_site) ) , 
                                  "Invalid Input!") /* CLD20190606 */
	with frame fmframe.

        ASSIGN l_boxq   = 0 
               l_s_boxq = 0. /* CLD20190606 */

	find first pt_mstr where pt_domain = global_domain AND pt_part = l_part 
             no-lock no-error no-wait.
	if available pt_mstr then do :
		assign l_boxq   = pt_ord_mult 
   		       l_shpwt  = pt_ship_wt
 		       l_netwt  = pt_net_wt .

		find first ptp_det where ptp_domain = global_domain AND ptp_part = l_part AND ptp_site = l_site
             		no-lock no-error no-wait.    /* CLD20190606 */
		if available ptp_det then 
			assign l_s_boxq   = ptp_ord_mult. /* CLD20190606 */

		disp pt_desc1
		     pt_desc2 
		     l_boxq
		     l_s_boxq /* CLD20190606 */
		     l_shpwt
		     l_netwt
		with frame fmframe.
		update
		     l_boxq 
                     l_s_boxq
   		     l_shpwt
 		     l_netwt

		with frame fmframe.
	end.
	else do:
		undo, retry.
	end.

/*	update l_ok 
		with frame fmframe. 
	if l_ok then do : CLD20200925 */

		find first pt_mstr  where pt_domain = global_domain AND 
                                          pt_part = l_part 
                                          exclusive-lock no-error.
		if available pt_mstr then do :
			assign pt_ord_mult = l_boxq
		     	       pt_ship_wt = l_shpwt
		               pt_net_wt = l_netwt .
		end.
		find first ptp_det where ptp_domain = global_domain AND
                                         ptp_part = l_part AND
                                         ptp_site = l_site 
					Exclusive-lock No-error. /* CLD20190606 */
		if available ptp_det then 
			assign ptp_ord_mult = l_s_boxq.  /* CLD20190606 */
		
	/* end. CLD20200925 */

end. /* mainloop */
