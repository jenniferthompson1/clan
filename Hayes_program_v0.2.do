/*

Do file to write code to do Hayes style cluster analysis

Stephen Nash
15 May 2019

*/
scalar drop _all // Just for my testing

/*
SYNTAX

hayes depvar [indepvars] [if] [in] , ARMs(varname) STRata(varname) CLUSter(varname) [ADJusted]

	arms must be coded 0/1 two arms only at the moment
	strata must be numbered categorical (but any number of levels)
	cluster must be numeric and "sensible" - it's used in the collapse, and that could cause problems...
	effect specifies if the user wants a risk ratio, risk difference...
	if adjusted is included an adjusted analysis will be performed
		it's fine if no indepvars are included though, gives the same result as unadj
		if adjusted not specified, but indepvars *are* included, they are simply ignored

*/

/*
█████▄░██░██▄░██░░▄███▄░░████▄░██▄░░▄██
██▄▄█▀░██░███▄██░██▀░▀██░██░██░░▀████▀░
██░░██░██░██▀███░███████░████▀░░░░██░░░
█████▀░██░██░░██░██░░░██░██░██░░░░██░░░
*/
/*
Unadjusted results should be
Prev ratio= 1.4702076(1.2320586, 1.2320586), p-value=.00035598
*/
** RISK RATIO
	cap program drop hayes_crt
	prog define hayes_crt , rclass
		version 15.1
		syntax varlist(numeric fv) [if] [in] , ARMs(varname) STRata(varname) CLUSter(varname) EFFect(string) [ADJusted]

		preserve // We're going to change the data - drop rows and create new vars
			capture keep `if' // Get rid of un-needed obs now
			capture keep `in'
			
			*************************************
			**
			** SYNTAX SECTION - CHECK THE PARAMETERS and CREATE SOME LOCALS
			**
			*************************************
			if "`effect'"!="rr" & "`effect'"!="rd" & "`effect'"!="poisson" & "`effect'"!="means" {
					dis as error "Unrecognised effect estimator"
					exit 198
				}
			*
			* Is arm coded 0, 1?
			*
			*
			* Is strata numeric and contain a sensible number of levels?
			*
			*
			* Is cluster numeric and sensible?
			
			*************************************
			**
			** RISK RATIO SECTION
			**
			*************************************
			qui {
				if "`effect'"=="rr" {
					tempname numstrata obs expected clincases zero howmanyzeros prev logprev logprev0 logprev1 prev_ratio logprev_ratio prev_ratio_lci prev_ratio_uci ts pval // Need diff numbers if more than one trial arm...?
					local outcome `1'  // Makes the code easier to read
					gen byte `obs' = 1 // So we can count number of clusters in each strata
					tab `strata'
					scalar `numstrata' = r(r)
					dis `numstrata'
					*
					* If adjusted analysis, we need to get expected number from a logistic
					* regression WITHOUT the treatment arm BEFORE we collapse data
					if "`adjusted'"!="" {
						logistic `varlist' i.`strata'
						predict `expected'
						collapse (sum) `outcome' `obs' `expected', by(`cluster' `strata' `arms') 
					}
						else collapse (sum) `outcome' `obs' , by(`cluster' `strata' `arms') 
					pause
					*replace know = 0 if commu==1 // Unstar this to test the code below
					* We'll be taking logs, so add 0.5 if cluster prev is zero
						bysort `cluster' `strata' `arms' : gen `clincases'=sum(`outcome')
						gen byte `zero' = 1 if `clincases'==0 // Marks clinics with zero cases
						gen `howmanyzeros' = sum(`zero') // Makes a constant, number of clinics with zero prev
						replace `outcome' = `outcome' + 0.5 if `howmanyzeros' > 0.5
					*
					* Calculate...
					if "`adjusted'"=="" gen `prev' = `outcome' / `obs' 
						else gen `prev' = `outcome' / `expected' 
					gen `logprev' = log(`prev')
					*
					* Need to check how trial arm is coded here...? Or more than one trial arm?
					sum `logprev' if `arms' == 1
					scalar `logprev1' = r(mean)
					sum `logprev' if `arms' ==0
					scalar `logprev0' = r(mean)
					scalar `logprev_ratio' = `logprev1' - `logprev0'
					scalar `prev_ratio' = exp(`logprev_ratio')
					dis "Prev ratio = " `prev_ratio'
					* 95% CI, p-value
						regress `logprev' i.`strata'##i.`arms'
						scalar sd = e(rmse)
						* c = number of cluster per arm assuming 2 arm trial - what about if not balanced?!
						local c = _N/2 // Assumes all rows are unique clusters, no empty rows
						dis "c=`c'"
						*degrees of freedom = total number of clusters minus 2 x number of strata (2S)
						* could also use e(df_r) from previous regression
						*20-2*2=16
						local df = _N - (2 * `numstrata')
						dis "df=`df'"
						scalar `prev_ratio_lci' = exp(`logprev_ratio' - invttail(`df', 0.025)*sd*sqrt(2/`c'))
						scalar `prev_ratio_uci' = exp(`logprev_ratio' + invttail(`df', 0.025)*sd*sqrt(2/`c'))
						scalar `ts' = sign(`logprev_ratio')*(`logprev_ratio' / (sd*sqrt(2/`c')))
						scalar `pval'=2*ttail(`df',`ts')
					*
					** DISPLAY RESULTS **
					noi dis as result "Prev ratio= " `prev_ratio' "; (" `prev_ratio_lci' ", " `prev_ratio_uci' "); p-value=" `pval'
					return scalar p = `pval'
					return scalar ub = `prev_ratio_uci'
					return scalar lb = `prev_ratio_lci'
					return scalar rr = `prev_ratio'
				} // end if RR
			} // end quitely

			*************************************
			**
			** RISK DIFFERENCE SECTION
			**
			*************************************
			qui {
				if "`effect'"=="rd" {
					tempname numstrata obs expected prev prev0 prev1 prev_diff prev_diff_lci prev_diff_uci ts pval 		

					local outcome `1'  // Makes the code easier to read
					gen byte `obs' = 1 // So we can count number of clusters in each strata
					tab `strata'
					scalar `numstrata' = r(r)
					dis `numstrata'
					*
					* If adjusted analysis, we need to get expected number from a logistic
					* regression WITHOUT the treatment arm BEFORE we collapse data
					if "`adjusted'"!="" {
						logistic `varlist' i.`strata'
						predict `expected'
						collapse (sum) `outcome' `obs' `expected', by(`cluster' `strata' `arms') 
					}
						else collapse (sum) `outcome' `obs' , by(`cluster' `strata' `arms') 
					*
					* Calculate...
					if "`adjusted'"=="" gen `prev' = `outcome' / `obs' 
						else gen `prev' = `outcome' / `expected' 
					sum `prev' if `arms' == 1
					scalar `prev1' = r(mean)
					sum `prev' if `arms' ==0
					scalar `prev0' = r(mean)
					scalar `prev_diff' = `prev1' - `prev0'
					* 95% CI, p-value
						regress `prev' i.`strata'##i.`arms'
						scalar sd = e(rmse)
						* c = number of cluster per arm assuming 2 arm trial - what about if not balanced?!
						local c = _N/2 // Assumes all rows are unique clusters, no empty rows
						dis "c=`c'"
						*degrees of freedom = total number of clusters minus 2 x number of strata (2S)
						* could also use e(df_r) from previous regression
						*20-2*2=16
						local df = _N - (2 * `numstrata')
						dis "df=`df'"
						scalar `prev_diff_lci' = `prev_diff' - invttail(`df', 0.025)*sd*sqrt(2/`c')
						scalar `prev_diff_uci' = `prev_diff' + invttail(`df', 0.025)*sd*sqrt(2/`c')
						scalar `ts' = sign(`prev_diff')*(`prev_diff' / (sd*sqrt(2/`c')))
						scalar `pval'=2*ttail(`df',`ts')
					*
					** DISPLAY RESULTS **
					noi dis as result "Prev difference= " `prev_diff' "; (" `prev_diff_lci' ", " `prev_diff_uci' "); p-value=" `pval'
					return scalar p = `pval'
					return scalar ub = `prev_diff_uci'
					return scalar lb = `prev_diff_lci'
					return scalar rd = `prev_diff'
				} // end if risk difference
			} // end quitely
			
			*************************************
			**
			** POISSON COUNT SECTION
			**
			*************************************
			qui {
				if "`effect'"=="poisson" {
					noi dis "Poisson section"
					
					
					
				} // end if poisson
			} // end quitely


			*************************************
			**
			** CONTINUOUS OUTCOME SECTION
			** Difference in means
			**
			*************************************
			qui {
				if "`effect'"=="means" {
					noi dis "Continuous section - difference of means"
					tempname numstrata obs expected mn mn0 mn1 mean_diff mean_diff_lci mean_diff_uci ts pval 		

					local outcome `1'  // Makes the code easier to read
					gen byte `obs' = 1 // So we can count number of clusters in each strata
					tab `strata'
					scalar `numstrata' = r(r)
					dis `numstrata'
					*
					* If adjusted analysis, we need to get expected number from a logistic
					* regression WITHOUT the treatment arm BEFORE we collapse data
					if "`adjusted'"!="" {
						regress `varlist' i.`strata'
						predict `expected'
						collapse (sum) `outcome' `obs' `expected', by(`cluster' `strata' `arms') 
					}
						else collapse (sum) `outcome' `obs' , by(`cluster' `strata' `arms') 
					*
					* Calculate...
					if "`adjusted'"=="" gen `mn' = `outcome' / `obs' 
						else gen `mn' = (`outcome' - `expected') / `obs' // THINK HERE
					sum `mn' if `arms' == 1
					scalar `mn1' = r(mean)
					sum `mn' if `arms' ==0
					scalar `mn0' = r(mean)
					scalar `mean_diff' = `mn1' - `mn0'
					* 95% CI, p-value
						regress `mn' i.`strata'##i.`arms'
						scalar sd = e(rmse)
						* c = number of cluster per arm assuming 2 arm trial - what about if not balanced?!
						local c = _N/2 // Assumes all rows are unique clusters, no empty rows
						dis "c=`c'"
						*degrees of freedom = total number of clusters minus 2 x number of strata (2S)
						* could also use e(df_r) from previous regression
						*20-2*2=16
						local df = _N - (2 * `numstrata')
						dis "df=`df'"
						scalar `mean_diff_lci' = `mean_diff' - invttail(`df', 0.025)*sd*sqrt(2/`c')
						scalar `mean_diff_uci' = `mean_diff' + invttail(`df', 0.025)*sd*sqrt(2/`c')
						scalar `ts' = sign(`mean_diff')*(`mean_diff' / (sd*sqrt(2/`c')))
						scalar `pval'=2*ttail(`df',`ts')
					*
					** DISPLAY RESULTS **
					noi dis as result "Mean difference= " `mean_diff' "; (" `mean_diff_lci' ", " `mean_diff_uci' "); p-value=" `pval'
					return scalar p = `pval'
					return scalar ub = `mean_diff_uci'
					return scalar lb = `mean_diff_lci'
					return scalar md = `mean_diff'
				



				} // end if continuous
			} // end quitely


	restore
end

