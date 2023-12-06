foreach var of varlist * {
	cap replace `var' = "" if `var'=="NA"
	destring `var',replace
}

label variable hstart_can_new "Housing Starts"
tsmktim time, start(1914m1) // Set time variable
tsline hstart_can_new if time>tm(1980m12) & time<tm(2020m1), title(Housing Starts from 1981 to 2019) // Plot graph to eyeball
graph export hstarts1980.jpg, replace
//use data from 1981m1 to 2009m12 (348 data sets. 120 for evaluation. cutoff at 2019m12)

*******************
*** Trend check ***
*******************
// Linear
reg hstart_can_new time if time>tm(1980m12) & time<tm(2010m1),r 
predict linfit
tsline hstart_can_new linfit if time>tm(2005m1) 
estimates store linfit

// Quadratic
gen time2=time^2
reg hstart_can_new time time2 if time>tm(1980m12) & time<tm(2010m1),r
predict quadfit
predict quad_resids, resid
tsline hstart_can_new quadfit if time>tm(2005m1) & time<tm(2020m1), title(Quadratic Fit)
graph export quadfit.jpg, replace
estimates store quadfit

// Exponential
nl (hstart_can_new={b0=0.1}*exp({b1}*time)) if time>tm(1980m12) & time<tm(2010m1) 
estimates store expfit

estimates stats linfit quadfit expfit 
// Quad model picked due to lowest AIC and BIC

ac quad_resids
graph export quadresids.jpg,replace
pac quad_resids // Autocorrelation of reisudals still present.


*************************
*** Seasonality check ***
*************************
tsline hstart_can_new if time>=tm(2000m1) & time<tm(2001m1), title(Housing Starts 2000 to 2001) // Plot graph to eyeball
graph export seasonalcheck2015.jpg, replace

tsline hstart_can_new if time>=tm(2001m1) & time<tm(2002m1), title(Housing Starts 2001 to 2002) // Plot graph to eyeball
graph export seasonalcheck2014.jpg, replace

tsline hstart_can_new if time>=tm(2002m1) & time<tm(2004m1), title(Housing Starts 2002 to 2004) // Plot graph to eyeball
graph export seasonalcheck2002.jpg, replace

gen m=month(dofm(time))
gen q=quarter(dofq(time))

// Monthly
xi: reg hstart_can_new i.m time time2 if time>=tm(1981m1) & time<=tm(2009m12)
// Quarterly
xi: reg hstart_can_new i.q time time2 if time>=tm(1981m1) & time<=tm(2009m12)

// no seasonality, p value and rsquared all insignificant


*************************
*** Cyclical check ******
*************************
ac hstart_can_new
graph export autocorr.jpg,replace
//autocorrelation doesn't die down
pac hstart_can_new
graph export partial.jpg,replace
//first 2 lags are very persistent, 13 and 14 lags present as well, and lag 37
//try AR(2), AR(12),AR(13),AR(14),AR(37) if needed

reg hstart_can_new L(1/2).hstart_can_new if time>tm(1980m12) & time<tm(2010m1),r
est store AR2
predict AR2_resids,resid
pac AR2_resids
corrgram AR2_resids
//AR2 is not it, fails eyeball test and Qtest: sqrt360 = 19 is non zero

//AR12
reg hstart_can_new L(1/12).hstart_can_new if time>tm(1980m12) & time<tm(2010m1),r
est store AR12
predict AR12_resids,resid
pac AR12_resids
corrgram AR12_resids
//fails Q test: lag21 is significant

//AR13
reg hstart_can_new L(1/13).hstart_can_new if time>tm(1980m12) & time<tm(2010m1),r
est store AR13
predict AR13_resids,resid
pac AR13_resids
graph export AR13residspacf.jpg,replace
kdensity AR13_resids
graph export kernelar13resids.jpg,replace
corrgram AR13_resids
//pac does not look like white noise
//passes Q test: lag 37 and all before that are all 0

//AR14
reg hstart_can_new L(1/14).hstart_can_new if time>tm(1980m12) & time<tm(2010m1),r
est store AR14
predict AR14_resids,resid
pac AR14_resids
corrgram AR14_resids
//passes Q test: lag 37 and all before that are all 0

//AR15
reg hstart_can_new L(1/15).hstart_can_new if time>tm(1980m12) & time<tm(2010m1),r
est store AR15
predict AR15_resids,resid
pac AR15_resids
corrgram AR15_resids
//passes Q test: lag 37 and all before that are all 0

est stats AR12 AR13 AR14 AR15
//choose  AR13

*********************
*** ADL Models ******
*********************

*****Testing GDP*****
reg hstart_can_new L(1/13).hstart_can_new gdp_new if time>tm(1981m2) & time<tm(2010m1),r
est store ADLgdp0

reg hstart_can_new L(1/13).hstart_can_new L.gdp_new if time>tm(1981m2) & time<tm(2010m1),r
est store ADLgdp1

reg hstart_can_new L(1/13).hstart_can_new L(1/2).gdp_new if time>tm(1981m2) & time<tm(2010m1),r
est store ADLgdp2

reg hstart_can_new L(1/13).hstart_can_new if time>tm(1981m2) & time<tm(2010m1),r
est store ADLnogdp

//reg hstart_can_new L(1/13).hstart_can_new L(1/3).gdp_new if time>tm(1981m3) & time<tm(2010m1),r
//est store ADLgdp3

est stats ADLnogdp ADLgdp0 ADLgdp1 ADLgdp2 //ADLgdp3   

//after running until lag 13, lag 2 had lowest AIC, removed lag 13 and reran. same results all the way until ADLgdp2 

//choose lag 2 for gdp_new

reg hstart_can_new L(1/13).hstart_can_new L(1/2).gdp_new if time>tm(1981m2) & time<tm(2010m1),r
//granger test
testparm L(1/2).gdp_new
//p-value actually quite high, but AIC suggests still better than pure AR8 so we'll stick with it

*****Testing Unemployment*****
reg hstart_can_new L(1/13).hstart_can_new unemp_can if time>tm(1981m2) & time<tm(2010m1),r
est store ADLun0

reg hstart_can_new L(1/13).hstart_can_new L.unemp_can if time>tm(1981m2) & time<tm(2010m1),r
est store ADLun1

reg hstart_can_new L(1/13).hstart_can_new L(1/2).unemp_can if time>tm(1981m2) & time<tm(2010m1),r
est store ADLun2

//reg hstart_can_new L(1/13).hstart_can_new L(1/3).unemp_can if time>tm(1981m1) & time<tm(2010m1),r
//est store ADLun3

// reg hstart_can_new L(1/13).hstart_can_new L(1/4).unemp_can if time>tm(1981m1) & time<tm(2010m1),r
//est store ADLun4

// reg hstart_can_new L(1/13).hstart_can_new L(1/12).unemp_can if time>tm(1981m2) & time<tm(2010m1),r
// est store ADLun12

// reg hstart_can_new L(1/13).hstart_can_new L(1/13).unemp_can if time>tm(1981m2) & time<tm(2010m1),r
// est store ADLun13

// reg hstart_can_new L(1/13).hstart_can_new L(1/14).unemp_can if time>tm(1981m2) & time<tm(2010m1),r
// est store ADLun14

est stats ADLun0 ADLun1 ADLun2 //ADLun3 ADLun4 // ADLun12 ADLun13 ADLun14

// ADLun2 is best based on AIC
reg hstart_can_new L(1/13).hstart_can_new L(1/2).gdp_new L(1/2).unemp_can if time>tm(1981m2) & time<tm(2010m1),r
testparm L(1/2).gdp_new 
//granger causality p-value much higher: insignificant
testparm L(1/2).unemp_can
//p-value quite high as well
est store ADLgdp2un2

reg hstart_can_new L(1/13).hstart_can_new if time>tm(1981m2) & time<tm(2010m1),r
est store AR13
reg hstart_can_new L(1/13).hstart_can_new L(1/2).unemp_can if time>tm(1981m2) & time<tm(2010m1),r
est store ADLun2
est stats AR13 ADLgdp2un2 ADLun2 ADLgdp2
//ADL un2 actually better than ADLgdp2un2. drop gdp from ADL model, just use unemployment.

reg hstart_can_new L(1/13).hstart_can_new L(1/2).unemp_can if time>tm(1980m1) & time<tm(2010m1),r
testparm L(1/2).unemp_can
//p-value is not very big, but still significant

//trying housing permits
reg hstart_can_new L(1/13).hstart_can_new nhouse_p_can if time>tm(1981m3) & time<tm(2010m1),r
est store ADLp0

reg hstart_can_new L(1/13).hstart_can_new L.nhouse_p_can if time>tm(1981m3) & time<tm(2010m1),r
est store ADLp1

reg hstart_can_new L(1/13).hstart_can_new L(1/2).nhouse_p_can if time>tm(1981m3) & time<tm(2010m1),r
est store ADLp2

reg hstart_can_new L(1/13).hstart_can_new L(1/3).nhouse_p_can if time>tm(1981m3) & time<tm(2010m1),r
est store ADLp3

//reg hstart_can_new L(1/13).hstart_can_new L(1/4).nhouse_p_can if time>tm(1981m4) & time<tm(2010m1),r
//est store ADLp4

//reg hstart_can_new L(1/13).hstart_can_new L(1/12).nhouse_p_can if time>tm(1981m12) & time<tm(2014m1),r
//est store ADLp12

//reg hstart_can_new L(1/13).hstart_can_new L(1/13).nhouse_p_can if time>tm(1982m1) & time<tm(2014m1),r
//est store ADLp13

//reg hstart_can_new L(1/13).hstart_can_new L(1/14).nhouse_p_can if time>tm(1982m2) & time<tm(2014m1),r
//est store ADLp14

est stats ADLp0 ADLp1 ADLp2 ADLp3 //ADLp4 //ADLp12 //ADLp13 //ADLp14

//repeat process. ADLp3 seems to be best
//run ADL with p3 and un2
reg hstart_can_new L(1/13).hstart_can_new L(1/2).unemp_can L(1/3).nhouse_p_can if time>tm(1981m3) & time<tm(2010m1),r
est store ADLun2p3
//granger causality
testparm L(1/3).nhouse_p_can
//p-value very very small, so housing permits likely to be very significant

//evaluating based on AIC
reg hstart_can_new L(1/13).hstart_can_new if time>tm(1981m3) & time<tm(2010m1),r
est store AR13
reg hstart_can_new L(1/13).hstart_can_new L(1/2).unemp_can if time>tm(1981m3) & time<tm(2010m1),r
est store ADLun2

est stats ADLun2p3 AR13 ADLun2 ADLp3
//adding housing permits greatly lowers AIC, making it much better

//trying cred_t_cb
reg hstart_can_new L(1/13).hstart_can_new cred_t_cb if time>tm(1981m2) & time<tm(2010m1),r
est store ADLcred0

reg hstart_can_new L(1/13).hstart_can_new L.cred_t_cb if time>tm(1981m2) & time<tm(2010m1),r
est store ADLcred1

reg hstart_can_new L(1/13).hstart_can_new L(1/2).cred_t_cb if time>tm(1981m2) & time<tm(2010m1),r
est store ADLcred2

//reg hstart_can_new L(1/13).hstart_can_new L(1/3).cred_t_cb if time>tm(1981m3) & time<tm(2010m1),r
//est store ADLcred3

//reg hstart_can_new L(1/13).hstart_can_new L(1/4).cred_t_cb if time>tm(1981m4) & time<tm(2014m1),r
//est store ADLcred4

//reg hstart_can_new L(1/13).hstart_can_new L(1/12).cred_t_cb if time>tm(1981m12) & time<tm(2014m1),r
//est store ADLcred12

//reg hstart_can_new L(1/13).hstart_can_new L(1/13).cred_t_cb if time>tm(1982m1) & time<tm(2014m1),r
//est store ADLcred13

//reg hstart_can_new L(1/13).hstart_can_new L(1/14).cred_t_cb if time>tm(1982m2) & time<tm(2014m1),r
//est store ADLcred14

est stats ADLcred0 ADLcred1 ADLcred2 //ADLcred3 //ADLcred4 //ADLcred12 //ADLcred13 //ADLcred14
//cred2 seems to be best, just slightly better than cred0

reg hstart_can_new L(1/13).hstart_can_new L(1/2).unemp_can L(1/3).nhouse_p_can L(1/2).cred_t_cb if time>tm(1981m3) & time<tm(2010m1),r
est store ADLun2p3cred2

est stat ADLun2p3 AR13 ADLun2p3cred2
//including credit actually worsens AIC
//drop cred2

//trying bank_rate

reg hstart_can_new L(1/13).hstart_can_new if time>tm(1981m1) & time<tm(2010m1),r
est store ADLnobr

reg hstart_can_new L(1/13).hstart_can_new bank_rate_l if time>tm(1981m1) & time<tm(2010m1),r
est store ADLbr0

//reg hstart_can_new L(1/13).hstart_can_new L.bank_rate_l if time>tm(1981m1) & time<tm(2010m1),r
//est store ADLbr1

//reg hstart_can_new L(1/13).hstart_can_new L(1/2).bank_rate_l if time>tm(1981m2) & time<tm(2014m1),r
//est store ADLbr2

//reg hstart_can_new L(1/13).hstart_can_new L(1/3).bank_rate_l if time>tm(1981m3) & time<tm(2014m1),r
//est store ADLbr3

//reg hstart_can_new L(1/13).hstart_can_new L(1/4).bank_rate_l if time>tm(1981m4) & time<tm(2014m1),r
//est store ADLbr4

//reg hstart_can_new L(1/13).hstart_can_new L(1/12).bank_rate_l if time>tm(1982m2) & time<tm(2014m1),r
//est store ADLbr12

//reg hstart_can_new L(1/13).hstart_can_new L(1/13).bank_rate_l if time>tm(1982m2) & time<tm(2014m1),r
//est store ADLbr13

//reg hstart_can_new L(1/13).hstart_can_new L(1/14).bank_rate_l if time>tm(1982m2) & time<tm(2014m1),r
//est store ADLbr14

est stats ADLnobr ADLbr0 //ADLbr1 //ADLbr2 //ADLbr3 //ADLbr4 //ADLbr12 ADLbr13 ADLbr14
//adding bank rate does not help. drop bank rate

//trying morgate rate
reg hstart_can_new L(1/13).hstart_can_new if time>tm(1981m4) & time<tm(2010m1),r
est store ADLnomor

reg hstart_can_new L(1/13).hstart_can_new mortg_1y if time>tm(1981m4) & time<tm(2010m1),r
est store ADLmor0

reg hstart_can_new L(1/13).hstart_can_new L.mortg_1y if time>tm(1981m4) & time<tm(2010m1),r
est store ADLmor1

reg hstart_can_new L(1/13).hstart_can_new L(1/2).mortg_1y if time>tm(1981m4) & time<tm(2010m1),r
est store ADLmor2

reg hstart_can_new L(1/13).hstart_can_new L(1/3).mortg_1y if time>tm(1981m4) & time<tm(2010m1),r
est store ADLmor3

reg hstart_can_new L(1/13).hstart_can_new L(1/4).mortg_1y if time>tm(1981m4) & time<tm(2010m1),r
est store ADLmor4

//reg hstart_can_new L(1/13).hstart_can_new L(1/5).mortg_1y if time>tm(1981m5) & time<tm(2010m1),r
//est store ADLmor5

//reg hstart_can_new L(1/13).hstart_can_new L(1/12).mortg_1y if time>tm(1982m1) & time<tm(2014m1),r
//est store ADLmor12

//reg hstart_can_new L(1/13).hstart_can_new L(1/13).mortg_1y if time>tm(1982m1) & time<tm(2014m1),r
//est store ADLmor13

//reg hstart_can_new L(1/13).hstart_can_new L(1/14).mortg_1y if time>tm(1982m2) & time<tm(2014m1),r
//est store ADLmor14

est stats ADLnomor ADLmor0 ADLmor1 ADLmor2 ADLmor3 ADLmor4 //ADLmor5 //ADLmor12 ADLmor13 ADLmor14
//ADL 4 seems to be best

reg hstart_can_new L(1/13).hstart_can_new L(1/2).unemp_can L(1/3).nhouse_p_can L(1/4).mortg_1y if time>tm(1981m3) & time<tm(2010m1),r
est store ADLun2p3mor4

est stat ADLun2p3 AR13 ADLun2p3mor4
//lowers AIC substantially. include morgage rate

//granger test
testparm L(1/4).mortg_1y
//significant

//trying exchange rate?
reg hstart_can_new L(1/13).hstart_can_new if time>tm(1981m5) & time<tm(2010m1),r
est store ADLnomor

reg hstart_can_new L(1/13).hstart_can_new usdcad_new if time>tm(1981m5) & time<tm(2010m1),r
est store ADLex0

reg hstart_can_new L(1/13).hstart_can_new L.usdcad_new if time>tm(1981m5) & time<tm(2010m1),r
est store ADLex1

reg hstart_can_new L(1/13).hstart_can_new L(1/2).usdcad_new if time>tm(1981m5) & time<tm(2010m1),r
est store ADLex2

reg hstart_can_new L(1/13).hstart_can_new L(1/3).usdcad_new if time>tm(1981m5) & time<tm(2010m1),r
est store ADLex3

reg hstart_can_new L(1/13).hstart_can_new L(1/4).usdcad_new if time>tm(1981m5) & time<tm(2010m1),r
est store ADLex4

reg hstart_can_new L(1/13).hstart_can_new L(1/5).usdcad_new if time>tm(1981m5) & time<tm(2010m1),r
est store ADLex5

//reg hstart_can_new L(1/13).hstart_can_new L(1/6).usdcad_new if time>tm(1981m6) & time<tm(2010m1),r
//est store ADLex6

//reg hstart_can_new L(1/13).hstart_can_new L(1/12).usdcad_new if time>tm(1982m2) & time<tm(2014m1),r
//est store ADLex12

//reg hstart_can_new L(1/13).hstart_can_new L(1/13).usdcad_new if time>tm(1982m2) & time<tm(2014m1),r
//est store ADLex13

//reg hstart_can_new L(1/13).hstart_can_new L(1/14).usdcad_new if time>tm(1982m2) & time<tm(2014m1),r
//est store ADLex14

est stats ADLnomor ADLex0 ADLex1 ADLex2 ADLex3 ADLex4 ADLex5 //ADLex6
//best is 5

reg hstart_can_new L(1/13).hstart_can_new L(1/2).unemp_can L(1/3).nhouse_p_can L(1/4).mortg_1y L(1/5).usdcad_new if time>tm(1981m3) & time<tm(2010m1),r
est store ADLun2pr3mor4ex5

est stat ADLun2p3 AR13 ADLun2p3mor4 ADLun2pr3mor4ex5 
// AIC worsens if we include exchange rate. drop it

//trying CPI
reg hstart_can_new L(1/13).hstart_can_new if time>tm(1980m12) & time<tm(2010m1),r
est store ADLnocpi

reg hstart_can_new L(1/13).hstart_can_new cpi_all_can if time>tm(1980m12) & time<tm(2010m1),r
est store ADLcpi0

//reg hstart_can_new L(1/13).hstart_can_new L.cpi_all_can if time>tm(1981m1) & time<tm(2010m1),r
//est store ADLcpi1

//reg hstart_can_new L(1/13).hstart_can_new L(1/2).cpi_all_can if time>tm(1981m2) & time<tm(2010m1),r
//est store ADLcpi2

//reg hstart_can_new L(1/13).hstart_can_new L(1/3).cpi_all_can if time>tm(1981m3) & time<tm(2010m1),r
//est store ADLcpi3

//reg hstart_can_new L(1/13).hstart_can_new L(1/4).cpi_all_can if time>tm(1981m4) & time<tm(2010m1),r
//est store ADLcpi4

//reg hstart_can_new L(1/13).hstart_can_new L(1/5).cpi_all_can if time>tm(1981m5) & time<tm(2010m1),r
//est store ADLcpi5

//reg hstart_can_new L(1/13).hstart_can_new L(1/12).cpi_all_can if time>tm(1981m12) & time<tm(2010m1),r
//est store ADLcpi12

//reg hstart_can_new L(1/13).hstart_can_new L(1/13).cpi_all_can if time>tm(1982m1) & time<tm(2010m1),r
//est store ADLcpi13

//reg hstart_can_new L(1/13).hstart_can_new L(1/14).cpi_all_can if time>tm(1982m2) & time<tm(2010m1),r
//est store ADLcpi14

est stat ADLnocpi ADLcpi0 //ADLcpi1 ADLcpi2 ADLcpi3 ADLcpi4 ADLcpi5 ADLcpi12 ADLcpi13 ADLcpi14
//model is better without CPI. drop it

//best model for now is ADLun2p3mor4

//Granger causality test for selected model
reg hstart_can_new L(1/13).hstart_can_new L(1/2).unemp_can L(1/3).nhouse_p_can L(1/4).mortg_1y time time2 if time>tm(1981m3) & time<tm(2010m1),r
est store fullmodel

testparm L(1/2).unemp
testparm L(1/3).nhouse_p_can
testparm L(1/4).mortg_1y

est stats fullmodel ADLun2p3mor4 ADLun2p3 ADLun2 AR13

****************************
******USING PLS*************
****************************
//confirming this model using PLS
//run regressions from 1981m1 to 2005m12, then use regression to forecast 2006m1 to 2009m12

//1981m1 = 805, 2005m12 = 1104, 2010m12= 1164
gen z=_n
gen y1=.
gen y2=.
gen y3=.
gen y4=.
forvalues p=1093/1152 {
	reg hstart_can_new L(1/13).hstart_can_new L(1/2).unemp_can L(1/3).nhouse_p_can L(1/4).mortg_1y time time2 if z>807 & z<`p', r 
	predict yhat
	replace y1=yhat if z==(`p')
	drop yhat
}
egen plsADL13un2p3mor4=mean((hstart_can_new-y1)^2)
replace plsADL13un2p3mor4=sqrt(plsADL13un2p3mor4)

forvalues p=1093/1152 {
	reg hstart_can_new L(1/13).hstart_can_new L(1/2).unemp_can L(1/3).nhouse_p_can time time2 if z>807 & z<`p', r 
	predict yhat
	replace y2=yhat if z==(`p')
	drop yhat
}
egen plsADL13un2p3=mean((hstart_can_new-y2)^2)
replace plsADL13un2p3=sqrt(plsADL13un2p3)

forvalues p=1093/1152 {
	reg hstart_can_new L(1/13).hstart_can_new L(1/2).unemp_can time time2 if z>807 & z<`p', r 
	predict yhat
	replace y3=yhat if z==(`p')
	drop yhat
}
egen plsADL13un2=mean((hstart_can_new-y3)^2)
replace plsADL13un2=sqrt(plsADL13un2)

forvalues p=1093/1152 {
	reg hstart_can_new L(1/13).hstart_can_new time time2 if z>807 & z<`p', r 
	predict yhat
	replace y4=yhat if z==(`p')
	drop yhat
}

egen plsADL13=mean((hstart_can_new-y4)^2)
replace plsADL13=sqrt(plsADL13)

//PLS selects ADL13un2p3, which is against AIC

************************************************************
************h-STEP AHEAD FORECAST USING MODEL 5*************
************************************************************

//Constructing 1 step ahead forecasts

reg hstart_can_new L(1/13).hstart_can_new L(1/2).unemp_can L(1/3).nhouse_p_can L(1/4).mortg_1y L(1/2).cred_t_cb time time2 if time>tm(1981m3) & time<tm(2010m1),r
predict final_resid, resid
ac final_resid

//Iterated method
forecast create ADL2322 , replace

reg hstart_can_new L(1/13).hstart_can_new L(1/2).unemp_can L(1/3).nhouse_p_can L(1/4).mortg_1y L(1/2).cred_t_cb time time2 if time>tm(1981m3) & time<tm(2010m1), r

estimates store model2322

forecast estimates model2322

set seed 2322

forecast solve, begin(tm(2010m1)) end(tm(2019m12)) simulate(residuals betas,statistic(stddev,prefix(sd_))reps(10000))

tsline hstart_can_new f_hstart_can_new if time>tm(2000m1)

gen iterU80=f_hstart_can_new+1.28*sd_ if time>tm(2009m12) & time<tm(2019m12)
gen iterL80=f_hstart_can_new-1.28*sd_ if time>tm(2009m12) & time<tm(2019m12)

gen iterU50=f_hstart_can_new+0.6745*sd_
gen iterL50=f_hstart_can_new-0.6745*sd_

tsline hstart_can_new f_hstart_can_new iterL80 iterU80 iterU50 iterL50 if time>tm(2008m1) & time<tm(2011m12), lpattern(solid solid longdash longdash shortdash shortdash) title(Iterated Forecast)
graph export iterated.jpg,replace

//direct forecast
gen diry=.
gen diryU80=.
gen diryL80=.
gen diryU50=.
gen diryL50=.
forvalues p=1/120{
	local q=`p'+12
	local d=`p'+1
	local f=`p'+2
	local g=`p'+3
	reg hstart_can_new L(`p'/`q').hstart_can_new L(`p'/`d').unemp_can L(`p'/`f').nhouse_p_can L(`p'/`g').mortg_1y L(`p'/`d').cred_t_cb time time2 if time>tm(1981m3) & time<tm(2010m1)
	predict yhat
	predict dir_stdf,stdf
	replace diry=yhat if (`p'+1152)==z
	replace diryU50=yhat+0.6745*dir_stdf if (`p'+1152)==z
	replace diryL50=yhat-0.6745*dir_stdf if (`p'+1152)==z
	replace diryU80=yhat+1.28*dir_stdf if (`p'+1152)==z
	replace diryL80=yhat-1.28*dir_stdf if (`p'+1152)==z
	drop yhat
	drop dir_stdf
}

tsline hstart_can_new diry diryU50 diryL50 diryU80 diryL80 if time>tm(2008m1) & time<tm(2011m12), lpattern(solid solid shortdash shortdash dash dash) title(Direct Forecast)

graph export direct.jpg,replace

*********************************************
************FORECAST COMBINATION*************
*********************************************
//simple averaging
//model1
gen model1=.
forvalues p=1/120{
	reg hstart_can_new L(1/13).hstart_can_new L(1/2).unemp_can L(1/3).nhouse_p_can L(1/4).mortg_1y time time2 if z>(`p'+806) & z<(`p'+1152), r
	if `p'==1{
	est store model1aic
	}
	predict yhat
	replace model1=yhat if z==(`p'+1152)
	drop yhat
}
egen forecastmodel1_rmse=mean((hstart_can_new-model1)^2)
replace forecastmodel1_rmse=sqrt(forecastmodel1_rmse)

//model 2, drop unemployment 
gen model2=.
forvalues p=1/120{
	reg hstart_can_new L(1/13).hstart_can_new L(1/4).mortg_1y L(1/3).nhouse_p_can time time2 if z>(`p'+806) & z<(`p'+1152), r
	if `p'==1{
	est store model2aic
	}
	predict yhat
	replace model2=yhat if z==(`p'+1152)
	drop yhat
}
egen forecastmodel2_rmse=mean((hstart_can_new-model2)^2)
replace forecastmodel2_rmse=sqrt(forecastmodel2_rmse)

//model 3, change lag of mortgage to 5
gen model3=.
forvalues p=1/120{
	reg hstart_can_new L(1/13).hstart_can_new L(1/2).unemp_can L(1/3).nhouse_p_can L(1/5).mortg_1y time time2 if z>(`p'+806) & z<(`p'+1152), r
	if `p'==1{
	est store model3aic
	}
	predict yhat
	replace model3=yhat if z==(`p'+1152)
	drop yhat
}
egen forecastmodel3_rmse=mean((hstart_can_new-model3)^2)
replace forecastmodel3_rmse=sqrt(forecastmodel3_rmse)

//model 4 change lag of housing permits to 2
gen model4=.
forvalues p=1/120{
	reg hstart_can_new L(1/13).hstart_can_new L(1/2).unemp_can L(1/2).nhouse_p_can L(1/4).mortg_1y time time2 if z>(`p'+806) & z<(`p'+1152), r
	if `p'==1{
	est store model4aic
	}
	predict yhat
	replace model4=yhat if z==(`p'+1152)
	drop yhat
}
egen forecastmodel4_rmse=mean((hstart_can_new-model4)^2)
replace forecastmodel4_rmse=sqrt(forecastmodel4_rmse)

//model 5 //add credit
gen model5=.
forvalues p=1/120{
	reg hstart_can_new L(1/13).hstart_can_new L(1/2).unemp_can L(1/3).nhouse_p_can L(1/4).mortg_1y L(1/2).cred_t_cb time time2 if z>(`p'+806) & z<(`p'+1152), r
	if `p'==1{
	est store model5aic
	}
	predict yhat
	replace model5=yhat if z==(`p'+1152)
	drop yhat
}
egen forecastmodel5_rmse=mean((hstart_can_new-model5)^2)
replace forecastmodel5_rmse=sqrt(forecastmodel5_rmse)

//average
gen forecastavg=.
replace forecastavg =(model1+model2+model3+model4+model5)/5

//finding rmse
egen forecastavg_rmse=mean((hstart_can_new-forecastavg)^2)
replace forecastavg_rmse=sqrt(forecastavg_rmse)

//2 step ahead
//model12
gen model12=.
forvalues p=1/120{
	reg hstart_can_new L(2/14).hstart_can_new L(2/3).unemp_can L(2/4).nhouse_p_can L(2/5).mortg_1y time time2 if z>(`p'+807) & z<(`p'+1152), r
	if `p'==1{
	est store model12aic
	}
	predict yhat
	replace model12=yhat if z==(`p'+1152)
	drop yhat
}
egen forecastmodel12_rmse=mean((hstart_can_new-model12)^2)
replace forecastmodel12_rmse=sqrt(forecastmodel12_rmse)

//model 22
gen model22=.
forvalues p=1/120{
	reg hstart_can_new L(2/14).hstart_can_new L(2/5).mortg_1y L(2/4).nhouse_p_can time time2 if z>(`p'+807) & z<(`p'+1152), r
	if `p'==1{
	est store model22aic
	}
	predict yhat
	replace model22=yhat if z==(`p'+1152)
	drop yhat
}
egen forecastmodel22_rmse=mean((hstart_can_new-model22)^2)
replace forecastmodel22_rmse=sqrt(forecastmodel22_rmse)

//model 32
gen model32=.
forvalues p=1/120{
	reg hstart_can_new L(2/14).hstart_can_new L(2/3).unemp_can L(2/4).nhouse_p_can L(2/6).mortg_1y time time2 if z>(`p'+807) & z<(`p'+1152), r
	if `p'==1{
	est store model32aic
	}
	predict yhat
	replace model32=yhat if z==(`p'+1152)
	drop yhat
}
egen forecastmodel32_rmse=mean((hstart_can_new-model32)^2)
replace forecastmodel32_rmse=sqrt(forecastmodel32_rmse)

//model 42
gen model42=.
forvalues p=1/120{
	reg hstart_can_new L(2/14).hstart_can_new L(2/3).unemp_can L(2/3).nhouse_p_can L(2/5).mortg_1y time time2 if z>(`p'+807) & z<(`p'+1152), r
	if `p'==1{
	est store model42aic
	}
	predict yhat
	replace model42=yhat if z==(`p'+1152)
	drop yhat
}
egen forecastmodel42_rmse=mean((hstart_can_new-model42)^2)
replace forecastmodel42_rmse=sqrt(forecastmodel42_rmse)

//model 52
gen model52=.
forvalues p=1/120{
	reg hstart_can_new L(2/14).hstart_can_new L(2/3).unemp_can L(2/4).nhouse_p_can L(2/5).mortg_1y L(2/3).cred_t_cb time time2 if z>(`p'+807) & z<(`p'+1152), r
	if `p'==1{
	est store model52aic
	}
	predict yhat
	replace model52=yhat if z==(`p'+1152)
	drop yhat
}
egen forecastmodel52_rmse=mean((hstart_can_new-model52)^2)
replace forecastmodel52_rmse=sqrt(forecastmodel52_rmse)

//average
gen forecastavg2=.
replace forecastavg2 =(model12+model22+model32+model42+model52)/5

//finding rmse
egen forecastavg2_rmse=mean((hstart_can_new-forecastavg2)^2)
replace forecastavg2_rmse=sqrt(forecastavg2_rmse)

//12 step ahead
//model112
gen model112=.
forvalues p=1/120{
	reg hstart_can_new L(13/25).hstart_can_new L(13/14).unemp_can L(13/15).nhouse_p_can L(13/16).mortg_1y time time2 if z>(`p'+818) & z<(`p'+1152), r
	if `p'==1{
	est store model112aic
	}
	predict yhat
	replace model112=yhat if z==(`p'+1152)
	drop yhat
}
egen forecastmodel112_rmse=mean((hstart_can_new-model112)^2)
replace forecastmodel112_rmse=sqrt(forecastmodel112_rmse)

//model 212
gen model212=.
forvalues p=1/120{
	reg hstart_can_new L(13/25).hstart_can_new L(13/16).mortg_1y L(13/15).nhouse_p_can time time2 if z>(`p'+818) & z<(`p'+1152), r
	if `p'==1{
	est store model212aic
	}
	predict yhat
	replace model212=yhat if z==(`p'+1152)
	drop yhat
}
egen forecastmodel212_rmse=mean((hstart_can_new-model212)^2)
replace forecastmodel212_rmse=sqrt(forecastmodel212_rmse)

//model 312
gen model312=.
forvalues p=1/120{
	reg hstart_can_new L(13/25).hstart_can_new L(13/14).unemp_can L(13/15).nhouse_p_can L(13/17).mortg_1y time time2 if z>(`p'+818) & z<(`p'+1152), r
	if `p'==1{
	est store model312aic
	}
	predict yhat
	replace model312=yhat if z==(`p'+1152)
	drop yhat
}
egen forecastmodel312_rmse=mean((hstart_can_new-model312)^2)
replace forecastmodel312_rmse=sqrt(forecastmodel312_rmse)

//model 412
gen model412=.
forvalues p=1/120{
	reg hstart_can_new L(13/25).hstart_can_new L(13/14).unemp_can L(13/14).nhouse_p_can L(13/16).mortg_1y time time2 if z>(`p'+818) & z<(`p'+1152), r
	if `p'==1{
	est store model412aic
	}
	predict yhat
	replace model412=yhat if z==(`p'+1152)
	drop yhat
}
egen forecastmodel412_rmse=mean((hstart_can_new-model412)^2)
replace forecastmodel412_rmse=sqrt(forecastmodel412_rmse)

//model 512
gen model512=.
forvalues p=1/120{
	reg hstart_can_new L(13/25).hstart_can_new L(13/14).unemp_can L(13/15).nhouse_p_can L(13/16).mortg_1y L(13/14).cred_t_cb time time2 if z>(`p'+818) & z<(`p'+1152), r
	if `p'==1{
	est store model512aic
	}
	predict yhat
	replace model512=yhat if z==(`p'+1152)
	drop yhat
}
egen forecastmodel512_rmse=mean((hstart_can_new-model512)^2)
replace forecastmodel512_rmse=sqrt(forecastmodel512_rmse)

//average
gen forecastavg12=.
replace forecastavg12 =(model112+model212+model312+model412+model512)/5

//finding rmse
egen forecastavg12_rmse=mean((hstart_can_new-forecastavg12)^2)
replace forecastavg12_rmse=sqrt(forecastavg12_rmse)

***********************
****GRANGER RAMANATHAN
***********************
//1 step ahead forecasts
reg hstart_can_new model1 model2 model3 model4 model5, noconstant

constraint 1 model1+model2+model3+model4+model5=1
cnsreg hstart_can_new model1 model2 model3 model4 model5, constraints(1) noconstant
//drop all but model3

constraint 2 model3=1
cnsreg hstart_can_new model3, constraints(2) noconstant

gen GRforecast_1step=model3
egen GRforecast_1step_rmse=mean((hstart_can_new-GRforecast_1step)^2)
replace GRforecast_1step_rmse=sqrt(GRforecast_1step_rmse)
//1 step ahead combi done

//2 step ahead forecasts
reg hstart_can_new model12 model22 model32 model42 model52, noconstant
//no collinearity

constraint 1 model12+model22+model32+model42+model52=1
cnsreg hstart_can_new model12 model22 model32 model42 model52, constraints(1) noconstant
//drop model32 model42

constraint 2 model12+model22+model52=1
cnsreg hstart_can_new model12 model22 model52, constraints(2) noconstant

gen GRforecast_2step=0.7334694*model12+0.1981323*model22+0.0683983*model52
egen GRforecast_2step_rmse=mean((hstart_can_new-GRforecast_2step)^2)
replace GRforecast_2step_rmse=sqrt(GRforecast_2step_rmse)
//2 step done

//12 step ahead
reg hstart_can_new model112 model212 model312 model412 model512, noconstant

constraint 1 model112+model212+model312+model412+model512=1
cnsreg hstart_can_new model112 model212 model312 model412 model512, constraints(1) noconstant
//drop model212 and model312

constraint 2 model112+model412+model512=1
cnsreg hstart_can_new model112 model412 model512, constraints(2) noconstant
//drop model112

constraint 3 model412+model512=1
cnsreg hstart_can_new model412 model512, constraints(3) noconstant

gen GRforecast_12step=0.2620778*model412+0.7379222*model512
egen GRforecast_12step_rmse=mean((hstart_can_new-GRforecast_12step)^2)
replace GRforecast_12step_rmse=sqrt(GRforecast_12step_rmse)
//12 step ahead done

***********************
**********BATES GRANGER
***********************
//1 step ahead

//model1 PLS (For Bates weights)
gen model1pls=.
forvalues p=1/60{
	reg hstart_can_new L(1/13).hstart_can_new L(1/2).unemp_can L(1/3).nhouse_p_can L(1/4).mortg_1y time time2 if z>(`p'+806) & z<(`p'+1092), r
	if `p'==1{
	est store model1aicpls
	}
	predict yhatpls
	replace model1pls=yhatpls if z==(`p'+1092)
	drop yhatpls
}
egen forecastmodel1_rmse_pls=mean((hstart_can_new-model1pls)^2)
replace forecastmodel1_rmse_pls=sqrt(forecastmodel1_rmse_pls)

//model2 PLS (For Bates weights)
gen model2pls=.
forvalues p=1/60{
	reg hstart_can_new L(1/13).hstart_can_new L(1/4).mortg_1y L(1/3).nhouse_p_can time time2 if z>(`p'+806) & z<(`p'+1092), r
	if `p'==1{
	est store model2aicpls
	}
	predict yhatpls
	replace model2pls=yhatpls if z==(`p'+1092)
	drop yhatpls
}
egen forecastmodel2_rmse_pls=mean((hstart_can_new-model2pls)^2)
replace forecastmodel2_rmse_pls=sqrt(forecastmodel2_rmse_pls)

//model3 PLS (For Bates weights)
gen model3pls=.
forvalues p=1/60{
	reg hstart_can_new L(1/13).hstart_can_new L(1/2).unemp_can L(1/3).nhouse_p_can L(1/5).mortg_1y time time2 if z>(`p'+806) & z<(`p'+1092), r
	if `p'==1{
	est store model3aicpls
	}
	predict yhatpls
	replace model3pls=yhatpls if z==(`p'+1092)
	drop yhatpls
}
egen forecastmodel3_rmse_pls=mean((hstart_can_new-model3pls)^2)
replace forecastmodel3_rmse_pls=sqrt(forecastmodel3_rmse_pls)

//model4 PLS (For Bates weights)
gen model4pls=.
forvalues p=1/60{
	reg hstart_can_new L(1/13).hstart_can_new L(1/2).unemp_can L(1/2).nhouse_p_can L(1/4).mortg_1y time time2 if z>(`p'+806) & z<(`p'+1092), r
	if `p'==1{
	est store model4aicpls
	}
	predict yhatpls
	replace model4pls=yhatpls if z==(`p'+1092)
	drop yhatpls
}
egen forecastmodel4_rmse_pls=mean((hstart_can_new-model4pls)^2)
replace forecastmodel4_rmse_pls=sqrt(forecastmodel4_rmse_pls)

//model5 PLS (For Bates weights)
gen model5pls=.
forvalues p=1/60{
	reg hstart_can_new L(1/13).hstart_can_new L(1/2).unemp_can L(1/3).nhouse_p_can L(1/4).mortg_1y L(1/2).cred_t_cb time time2 if z>(`p'+806) & z<(`p'+1092), r
	if `p'==1{
	est store model5aicpls
	}
	predict yhatpls
	replace model5pls=yhatpls if z==(`p'+1092)
	drop yhatpls
}
egen forecastmodel5_rmse_pls=mean((hstart_can_new-model5pls)^2)
replace forecastmodel5_rmse_pls=sqrt(forecastmodel5_rmse_pls)

//1 step ahead
//weights calculated in Excel
gen BGforecast_1step=0.200200652*model1+0.205837164*model2+0.199678673*model3+0.198175172*model4+0.196108339*model5
egen BGforecast_1step_rmse=mean((hstart_can_new-BGforecast_1step)^2)
replace BGforecast_1step_rmse=sqrt(BGforecast_1step_rmse)

//2 steps ahead
//model12 PLS (For Bates weights)
gen model12pls=.
forvalues p=1/60{
	reg hstart_can_new L(2/14).hstart_can_new L(2/3).unemp_can L(2/4).nhouse_p_can L(2/5).mortg_1y time time2 if z>(`p'+807) & z<(`p'+1092), r
	if `p'==1{
	est store model12aicpls
	}
	predict yhatpls
	replace model12pls=yhatpls if z==(`p'+1092)
	drop yhatpls
}
egen forecastmodel12_rmse_pls=mean((hstart_can_new-model12pls)^2)
replace forecastmodel12_rmse_pls=sqrt(forecastmodel12_rmse_pls)

//model22 PLS (For Bates weights)
gen model22pls=.
forvalues p=1/60{
	reg hstart_can_new L(2/14).hstart_can_new L(2/5).mortg_1y L(2/4).nhouse_p_can time time2 if z>(`p'+807) & z<(`p'+1092), r
	if `p'==1{
	est store model22aicpls
	}
	predict yhatpls
	replace model22pls=yhatpls if z==(`p'+1092)
	drop yhatpls
}
egen forecastmodel22_rmse_pls=mean((hstart_can_new-model22pls)^2)
replace forecastmodel22_rmse_pls=sqrt(forecastmodel22_rmse_pls)

//model32 PLS (For Bates weights)
gen model32pls=.
forvalues p=1/60{
	reg hstart_can_new L(2/14).hstart_can_new L(2/3).unemp_can L(2/4).nhouse_p_can L(2/6).mortg_1y time time2 if z>(`p'+807) & z<(`p'+1092), r
	if `p'==1{
	est store model32aicpls
	}
	predict yhatpls
	replace model32pls=yhatpls if z==(`p'+1092)
	drop yhatpls
}
egen forecastmodel32_rmse_pls=mean((hstart_can_new-model32pls)^2)
replace forecastmodel32_rmse_pls=sqrt(forecastmodel32_rmse_pls)

//model42 PLS (For Bates weights)
gen model42pls=.
forvalues p=1/60{
	reg hstart_can_new L(2/14).hstart_can_new L(2/3).unemp_can L(2/3).nhouse_p_can L(2/5).mortg_1y time time2 if z>(`p'+807) & z<(`p'+1092), r
	if `p'==1{
	est store model42aicpls
	}
	predict yhatpls
	replace model42pls=yhatpls if z==(`p'+1092)
	drop yhatpls
}
egen forecastmodel42_rmse_pls=mean((hstart_can_new-model42pls)^2)
replace forecastmodel42_rmse_pls=sqrt(forecastmodel42_rmse_pls)

//model52 PLS (For Bates weights)
gen model52pls=.
forvalues p=1/60{
	reg hstart_can_new L(2/14).hstart_can_new L(2/3).unemp_can L(2/4).nhouse_p_can L(2/5).mortg_1y L(2/3).cred_t_cb time time2 if z>(`p'+807) & z<(`p'+1092), r
	if `p'==1{
	est store model52aicpls
	}
	predict yhatpls
	replace model52pls=yhatpls if z==(`p'+1092)
	drop yhatpls
}
egen forecastmodel52_rmse_pls=mean((hstart_can_new-model52pls)^2)
replace forecastmodel52_rmse_pls=sqrt(forecastmodel52_rmse_pls)

//2 steps ahead
//weights calculated in excel
gen BGforecast_2step=0.201359588*model12+0.202923945*model22+0.2048208*model32+0.195623986*model42+0.19527168*model52
egen BGforecast_2step_rmse=mean((hstart_can_new-BGforecast_2step)^2)
replace BGforecast_2step_rmse=sqrt(BGforecast_2step_rmse)

//12 steps ahead
//model112 PLS (For Bates weights)
gen model112pls=.
forvalues p=1/60{
	reg hstart_can_new L(13/25).hstart_can_new L(13/14).unemp_can L(13/15).nhouse_p_can L(13/16).mortg_1y time time2 if z>(`p'+818) & z<(`p'+1092), r
	if `p'==1{
	est store model112aicpls
	}
	predict yhatpls
	replace model112pls=yhatpls if z==(`p'+1092)
	drop yhatpls
}
egen forecastmodel112_rmse_pls=mean((hstart_can_new-model112pls)^2)
replace forecastmodel112_rmse_pls=sqrt(forecastmodel112_rmse_pls)

//model212 PLS (For Bates weights)
gen model212pls=.
forvalues p=1/60{
	reg hstart_can_new L(13/25).hstart_can_new L(13/16).mortg_1y L(13/15).nhouse_p_can time time2 if z>(`p'+818) & z<(`p'+1092), r
	if `p'==1{
	est store model212aicpls
	}
	predict yhatpls
	replace model212pls=yhatpls if z==(`p'+1092)
	drop yhatpls
}
egen forecastmodel212_rmse_pls=mean((hstart_can_new-model212pls)^2)
replace forecastmodel212_rmse_pls=sqrt(forecastmodel212_rmse_pls)

//model312 PLS (For Bates weights)
gen model312pls=.
forvalues p=1/60{
	reg hstart_can_new L(13/25).hstart_can_new L(13/14).unemp_can L(13/15).nhouse_p_can L(13/17).mortg_1y time time2 if z>(`p'+818) & z<(`p'+1092), r
	if `p'==1{
	est store model312aicpls
	}
	predict yhatpls
	replace model312pls=yhatpls if z==(`p'+1092)
	drop yhatpls
}
egen forecastmodel312_rmse_pls=mean((hstart_can_new-model312pls)^2)
replace forecastmodel312_rmse_pls=sqrt(forecastmodel312_rmse_pls)

//model412 PLS (For Bates weights)
gen model412pls=.
forvalues p=1/60{
	reg hstart_can_new L(13/25).hstart_can_new L(13/14).unemp_can L(13/14).nhouse_p_can L(13/16).mortg_1y time time2 if z>(`p'+818) & z<(`p'+1092), r
	if `p'==1{
	est store model412aicpls
	}
	predict yhatpls
	replace model412pls=yhatpls if z==(`p'+1092)
	drop yhatpls
}
egen forecastmodel412_rmse_pls=mean((hstart_can_new-model412pls)^2)
replace forecastmodel412_rmse_pls=sqrt(forecastmodel412_rmse_pls)

//model512 PLS (For Bates weights)
gen model512pls=.
forvalues p=1/60{
	reg hstart_can_new L(13/25).hstart_can_new L(13/14).unemp_can L(13/15).nhouse_p_can L(13/16).mortg_1y L(13/14).cred_t_cb time time2 if z>(`p'+818) & z<(`p'+1092), r
	if `p'==1{
	est store model512aicpls
	}
	predict yhatpls
	replace model512pls=yhatpls if z==(`p'+1092)
	drop yhatpls
}
egen forecastmodel512_rmse_pls=mean((hstart_can_new-model512pls)^2)
replace forecastmodel512_rmse_pls=sqrt(forecastmodel512_rmse_pls)

//12 steps ahead
//weights calculated in excel
gen BGforecast_12step=0.204493096*model112+0.198181992*model212+0.201398423*model312+0.196106755*model412+0.199819733*model512
egen BGforecast_12step_rmse=mean((hstart_can_new-BGforecast_12step)^2)
replace BGforecast_12step_rmse=sqrt(BGforecast_12step_rmse)

****************WEIGHTED AIC****
********************************
est stats model1aic model2aic model3aic model4aic model5aic model12aic model22aic model32aic model42aic model52aic model112aic model212aic model312aic model412aic model512aic

//weights generated in excel
//1 step
gen WAICforecast_1step=0.283006226*model1+0.065265848*model2+0.104216336*model3+0.010527269*model4+0.536984321*model5

egen WAICforecast_1step_rmse=mean((hstart_can_new-WAICforecast_1step)^2)
replace WAICforecast_1step_rmse=sqrt(WAICforecast_1step_rmse)

//2 step
gen WAICforecast_2step=0.248781253*model12+0.286023509*model22+0.14991583*model32+0.00574353*model42+0.309535878*model52

egen WAICforecast_2step_rmse=mean((hstart_can_new-WAICforecast_2step)^2)
replace WAICforecast_2step_rmse=sqrt(WAICforecast_2step_rmse)

//12 step
gen WAICforecast_12step=0.321285195*model112+0.061119391*model212+0.192160159*model312+0.376654826*model412+0.048780429*model512

egen WAICforecast_12step_rmse=mean((hstart_can_new-WAICforecast_12step)^2)
replace WAICforecast_12step_rmse=sqrt(WAICforecast_12step_rmse)

************FORECAST EVALUATION*************
//1 step
gen GRforecast_1step_error=hstart_can_new-GRforecast_1step
ac GRforecast_1step_error, title(Autocorrelations of Error from 1-Step Ahead Forecast)
graph export acf1step.jpg,replace
//errors uncorellated: good!
//MZ reg
reg hstart_can_new GRforecast_1step if time>tm(2009m12) & time<tm(2020m1),r

test (_cons==0) (GRforecast_1step==1)
//constant is not 0 and coeff is not 1. There is bias.

//compare with Bates Granger

dmariano hstart_can_new GRforecast_1step BGforecast_1step, crit(MSE) maxlag(0) kernel(bartlett)
//p-value is high: both forecasts are statiscally the same

//compare with simple averaging
dmariano hstart_can_new GRforecast_1step forecastavg, crit(MSE) maxlag(0) kernel(bartlett)
//p-value is high: both forecasts are statistically the same

//2 step
gen GRforecast_2step_error=hstart_can_new-GRforecast_2step
ac GRforecast_2step_error
graph export acf2stepforecast.jpg,replace
//correlation only in 1st lag: good!
disp 0.75*(120)^(1/3)
newey hstart_can_new GRforecast_2step if time>tm(2009m12) & time<tm(2020m1),lag(4)
test (_cons==0) (GRforecast_2step==1)
//small p-value: constant is not 0 and coeff is not 1. There is bias

//compare with simple averaging
dmariano hstart_can_new GRforecast_2step forecastavg2, crit(MSE) maxlag(4) kernel(bartlett)
//small p-value: statistically the same as simple averaging

//compare with WAIC
dmariano hstart_can_new GRforecast_2step WAICforecast_2step, crit(MSE) maxlag(4) kernel(bartlett)
//small p-value: statistically the same as WAIC


//12 step
gen GRforecast_12step_error=hstart_can_new-GRforecast_12step
ac GRforecast_12step_error
//there is some correlation until 10 lags: good!
newey hstart_can_new GRforecast_12step if time>tm(2009m12) & time<tm(2020m1),lag(4)
test (_cons==0) (GRforecast_12step==1)
//small p-value: constant is not 0 and coeff is not 1. There is bias

//compare with simple averaging
dmariano hstart_can_new GRforecast_12step forecastavg12, crit(MSE) maxlag(4) kernel(bartlett)
//p-value small. for 12 step ahead GR is better than simple forcasting statistically significant

//compare with model5 without any combination
dmariano hstart_can_new GRforecast_12step model512, crit(MSE) maxlag(4) kernel(bartlett)
//p-value high

//comparing with other methods
dmariano hstart_can_new GRforecast_12step BGforecast_12step, crit(MSE) maxlag(4) kernel(bartlett)
//small p-value: GR better
dmariano hstart_can_new GRforecast_12step WAICforecast_12step, crit(MSE) maxlag(4) kernel(bartlett)
//small p-value: GR better

********************
***FINAL FORECAST***
********************

//getting forecasts for the other steps
// 3 step ahead forecast
//generate forecast in each model first

forvalues r=3/11{
	gen model1`r'=.
	local q=`r'+12
	local w=`r'+1
	local e=`r'+2
	local t=`r'+3
	local u=`r'+4
	forvalues p=1/120{
		reg hstart_can_new L(`r'/`q').hstart_can_new L(`r'/`w').unemp_can L(`r'/`e').nhouse_p_can L(`r'/`t').mortg_1y time time2 if z>(`p'+818) & z<(`p'+1152), r
		if `p'==1{
		est store model1`r'aic
		}
		predict yhat
		replace model1`r'=yhat if z==(`p'+1152)
		drop yhat
	}
	egen forecastmodel1`r'_rmse=mean((hstart_can_new-model1`r')^2)
	replace forecastmodel1`r'_rmse=sqrt(forecastmodel1`r'_rmse)

	//model 212
	gen model2`r'=.
	forvalues p=1/120{
		reg hstart_can_new L(`r'/`q').hstart_can_new L(`r'/`t').mortg_1y L(`r'/`e').nhouse_p_can time time2 if z>(`p'+818) & z<(`p'+1152), r
		if `p'==1{
		est store model2`r'aic
		}
		predict yhat
		replace model2`r'=yhat if z==(`p'+1152)
		drop yhat
	}
	egen forecastmodel2`r'_rmse=mean((hstart_can_new-model2`r')^2)
	replace forecastmodel2`r'_rmse=sqrt(forecastmodel2`r'_rmse)

	//model 312
	gen model3`r'=.
	forvalues p=1/120{
		reg hstart_can_new L(`r'/`q').hstart_can_new L(`r'/`w').unemp_can L(`r'/`e').nhouse_p_can L(`r'/`u').mortg_1y time time2 if z>(`p'+818) & z<(`p'+1152), r
		if `p'==1{
		est store model3`r'aic
		}
		predict yhat
		replace model3`r'=yhat if z==(`p'+1152)
		drop yhat
	}
	egen forecastmodel3`r'_rmse=mean((hstart_can_new-model3`r')^2)
	replace forecastmodel3`r'_rmse=sqrt(forecastmodel3`r'_rmse)

	//model 412
	gen model4`r'=.
	forvalues p=1/120{
		reg hstart_can_new L(`r'/`q').hstart_can_new L(`r'/`w').unemp_can L(`r'/`w').nhouse_p_can L(`r'/`t').mortg_1y time time2 if z>(`p'+818) & z<(`p'+1152), r
		if `p'==1{
		est store model4`r'aic
		}
		predict yhat
		replace model4`r'=yhat if z==(`p'+1152)
		drop yhat
	}
	egen forecastmodel4`r'_rmse=mean((hstart_can_new-model4`r')^2)
	replace forecastmodel4`r'_rmse=sqrt(forecastmodel4`r'_rmse)

	//model 512
	gen model5`r'=.
	forvalues p=1/120{
		reg hstart_can_new L(`r'/`q').hstart_can_new L(`r'/`w').unemp_can L(`r'/`e').nhouse_p_can L(`r'/`t').mortg_1y L(`r'/`w').cred_t_cb time time2 if z>(`p'+818) & z<(`p'+1152), r
		if `p'==1{
		est store model5`r'aic
		}
		predict yhat
		replace model5`r'=yhat if z==(`p'+1152)
		drop yhat
	}
	egen forecastmodel5`r'_rmse=mean((hstart_can_new-model5`r')^2)
	replace forecastmodel5`r'_rmse=sqrt(forecastmodel5`r'_rmse)
}

//using Granger Ramanathan for all to determine weights
//3 step
reg hstart_can_new model13 model23 model33 model43 model53, noconstant

constraint 1 model13+model23+model33+model43+model53=1
cnsreg hstart_can_new model13 model23 model33 model43 model53, constraints(1) noconstant
//drop model23 and model43
constraint 2 model13+model33+model53=1
cnsreg hstart_can_new model13  model33  model53, constraints(2) noconstant
//3step forecast+error
gen GRforecast_3step=0.4283553*model13+0.4010177*model33+0.170627*model53
egen GRforecast_3step_rmse=mean((hstart_can_new-GRforecast_3step)^2)
replace GRforecast_3step_rmse=sqrt(GRforecast_3step_rmse)

//4 step
reg hstart_can_new model14 model24 model34 model44 model54, noconstant

constraint 1 model14+model24+model34+model44+model54=1
cnsreg hstart_can_new model14 model24 model34 model44 model54, constraints(1) noconstant
//drop model24 model34 and model44
constraint 2 model14+model54=1
cnsreg hstart_can_new model14   model54, constraints(2) noconstant
//4step forecast+error
gen GRforecast_4step=0.8469064*model14+0.1530936*model54
egen GRforecast_4step_rmse=mean((hstart_can_new-GRforecast_4step)^2)
replace GRforecast_4step_rmse=sqrt(GRforecast_4step_rmse)

//5 step
reg hstart_can_new model15 model25 model35 model45 model55, noconstant

constraint 1 model15+model25+model35+model45+model55=1
cnsreg hstart_can_new model15 model25 model35 model45 model55, constraints(1) noconstant
//drop model25 model35 and model45
constraint 2 model15+model55=1
cnsreg hstart_can_new model15   model55, constraints(2) noconstant
//5step forecast+error
gen GRforecast_5step=0.6036947*model15+0.3963053*model55
egen GRforecast_5step_rmse=mean((hstart_can_new-GRforecast_5step)^2)
replace GRforecast_5step_rmse=sqrt(GRforecast_5step_rmse)

//6 step
reg hstart_can_new model16 model26 model36 model46 model56, noconstant

constraint 1 model16+model26+model36+model46+model56=1
cnsreg hstart_can_new model16 model26 model36 model46 model56, constraints(1) noconstant
//drop model16 and model26
constraint 2 model36+model46+model56=1
cnsreg hstart_can_new model36 model46 model56, constraints(2) noconstant
//6step forecast+error
gen GRforecast_6step=0.4254579*model36+0.0032884*model46+0.5712537*model56
egen GRforecast_6step_rmse=mean((hstart_can_new-GRforecast_6step)^2)
replace GRforecast_6step_rmse=sqrt(GRforecast_6step_rmse)

//7 step
reg hstart_can_new model17 model27 model37 model47 model57, noconstant

constraint 1 model17+model27+model37+model47+model57=1
cnsreg hstart_can_new model17 model27 model37 model47 model57, constraints(1) noconstant
//drop model27 model37 model47
constraint 2 model17+model57=1
cnsreg hstart_can_new model17 model57, constraints(2) noconstant
//7step forecast+error
gen GRforecast_7step=0.3990037*model17+0.6009963*model57
egen GRforecast_7step_rmse=mean((hstart_can_new-GRforecast_7step)^2)
replace GRforecast_7step_rmse=sqrt(GRforecast_7step_rmse)

//8 step
reg hstart_can_new model18 model28 model38 model48 model58, noconstant

constraint 1 model18+model28+model38+model48+model58=1
cnsreg hstart_can_new model18 model28 model38 model48 model58, constraints(1) noconstant
//drop model28 and model38
constraint 2 model18+model48+model58=1
cnsreg hstart_can_new model18 model48 model58, constraints(2) noconstant
//drop model18
constraint 3 model48+model58=1
cnsreg hstart_can_new model48 model58, constraints(3) noconstant
//8step forecast+error
gen GRforecast_8step=0.4008763*model48+0.5991237*model58
egen GRforecast_8step_rmse=mean((hstart_can_new-GRforecast_8step)^2)
replace GRforecast_8step_rmse=sqrt(GRforecast_8step_rmse)

//9 step
reg hstart_can_new model19 model29 model39 model49 model59, noconstant

constraint 1 model19+model29+model39+model49+model59=1
cnsreg hstart_can_new model19 model29 model39 model49 model59, constraints(1) noconstant
//drop model19 and model39
constraint 2 model29+model49+model59=1
cnsreg hstart_can_new model29 model49 model59, constraints(2) noconstant
//9step forecast+error
gen GRforecast_9step=0.1237997*model29+0.20900537*model49+0.6671465*model59
egen GRforecast_9step_rmse=mean((hstart_can_new-GRforecast_9step)^2)
replace GRforecast_9step_rmse=sqrt(GRforecast_9step_rmse)

//10 step
reg hstart_can_new model110 model210 model310 model410 model510, noconstant

constraint 1 model110+model210+model310+model410+model510=1
cnsreg hstart_can_new model110 model210 model310 model410 model510, constraints(1) noconstant
//drop model310
constraint 2 model110+model210+model410+model510=1
cnsreg hstart_can_new model110 model210 model410 model510, constraints(2) noconstant
//drop model110
constraint 3 model210+model410+model510=1
cnsreg hstart_can_new model210 model410 model510, constraints(3) noconstant
//drop model210
constraint 4 model410+model510=1
cnsreg hstart_can_new model410 model510, constraints(4) noconstant
//10step forecast+error
gen GRforecast_10step=0.395381*model410+0.604619*model510
egen GRforecast_10step_rmse=mean((hstart_can_new-GRforecast_10step)^2)
replace GRforecast_10step_rmse=sqrt(GRforecast_10step_rmse)

//11 step
reg hstart_can_new model111 model211 model311 model411 model511, noconstant

constraint 1 model111+model211+model311+model411+model511=1
cnsreg hstart_can_new model111 model211 model311 model411 model511, constraints(1) noconstant
//drop model311
constraint 2 model111+model211+model411+model511=1
cnsreg hstart_can_new model111 model211 model411 model511, constraints(2) noconstant
//drop model111
constraint 3 model211+model411+model511=1
cnsreg hstart_can_new model211 model411 model511, constraints(3) noconstant
//drop model211
constraint 4 model411+model511=1
cnsreg hstart_can_new model411 model511, constraints(4) noconstant
//11step forecast+error
gen GRforecast_11step=0.2787217*model411+0.7212783*model511
egen GRforecast_11step_rmse=mean((hstart_can_new-GRforecast_11step)^2)
replace GRforecast_11step_rmse=sqrt(GRforecast_11step_rmse)

***************ACTUAL FORECASTING*****************

//Using Granger Ramanathan
forvalues p=1/12{
	local q=`p'+12
	local w=`p'+1
	local e=`p'+2
	local r=`p'+3
	local t=`p'+4
	//model1
	reg hstart_can_new L(`p'/`q').hstart_can_new L(`p'/`w').unemp_can L(`p'/`e').nhouse_p_can L(`p'/`r').mortg_1y time time2 if time>tm(1980m12) & time<tm(2020m1),r
	predict x1_`p' if time==tm(2020m`p')
	//model2
	reg hstart_can_new L(`p'/`q').hstart_can_new L(`p'/`e').nhouse_p_can L(`p'/`r').mortg_1y time time2 if time>tm(1980m12) & time<tm(2020m1),r
	predict x2_`p' if time==tm(2020m`p')
	//model3
	reg hstart_can_new L(`p'/`q').hstart_can_new L(`p'/`w').unemp_can L(`p'/`e').nhouse_p_can L(`p'/`t').mortg_1y time time2 if time>tm(1980m12) & time<tm(2020m1),r
	predict x3_`p' if time==tm(2020m`p')
	//model4
	reg hstart_can_new L(`p'/`q').hstart_can_new L(`p'/`w').unemp_can L(`p'/`w').nhouse_p_can L(`p'/`r').mortg_1y time time2 if time>tm(1980m12) & time<tm(2020m1),r
	predict x4_`p' if time==tm(2020m`p')

	reg hstart_can_new L(`p'/`q').hstart_can_new L(`p'/`w').unemp_can L(`p'/`e').nhouse_p_can L(`p'/`r').mortg_1y L(`p'/`w').cred_t_cb time time2 if time>tm(1980m12) & time<tm(2020m1),r
	predict x5_`p' if time==tm(2020m`p')
}


//generating forecasts with 50% intervals
gen forecastfinal_1step=x3_1
gen forecastfinal_1step_50U=forecastfinal_1step+0.6745*GRforecast_1step_rmse
gen forecastfinal_1step_50L=forecastfinal_1step-0.6745*GRforecast_1step_rmse

gen forecastfinal_2step=0.7334694*x1_2+0.1981323*x2_2+0.0683983*x5_2
gen forecastfinal_2step_50U=forecastfinal_2step+0.6745*GRforecast_2step_rmse
gen forecastfinal_2step_50L=forecastfinal_2step-0.6745*GRforecast_2step_rmse

gen forecastfinal_3step=0.4283553*x1_3+0.4010177*x3_3+0.170627*x5_3
gen forecastfinal_3step_50U=forecastfinal_3step+0.6745*GRforecast_3step_rmse
gen forecastfinal_3step_50L=forecastfinal_3step-0.6745*GRforecast_3step_rmse

gen forecastfinal_4step=0.8469064*x1_4+0.1530936*x5_4
gen forecastfinal_4step_50U=forecastfinal_4step+0.6745*GRforecast_4step_rmse
gen forecastfinal_4step_50L=forecastfinal_4step-0.6745*GRforecast_4step_rmse

gen forecastfinal_5step=0.6036947*x1_5+0.3963053*x5_5
gen forecastfinal_5step_50U=forecastfinal_5step+0.6745*GRforecast_5step_rmse
gen forecastfinal_5step_50L=forecastfinal_5step-0.6745*GRforecast_5step_rmse

gen forecastfinal_6step=0.4254579*x3_6+0.0032884*x4_6+0.5712537*x5_6
gen forecastfinal_6step_50U=forecastfinal_6step+0.6745*GRforecast_6step_rmse
gen forecastfinal_6step_50L=forecastfinal_6step-0.6745*GRforecast_6step_rmse

gen forecastfinal_7step=0.3990037*x1_7+0.6009963*x5_7
gen forecastfinal_7step_50U=forecastfinal_7step+0.6745*GRforecast_7step_rmse
gen forecastfinal_7step_50L=forecastfinal_7step-0.6745*GRforecast_7step_rmse

gen forecastfinal_8step=0.4008763*x4_8+0.5991237*x5_8
gen forecastfinal_8step_50U=forecastfinal_8step+0.6745*GRforecast_8step_rmse
gen forecastfinal_8step_50L=forecastfinal_8step-0.6745*GRforecast_8step_rmse

gen forecastfinal_9step=0.1237997*x2_9+0.20900537*x4_9+0.6671465*x5_9
gen forecastfinal_9step_50U=forecastfinal_9step+0.6745*GRforecast_9step_rmse
gen forecastfinal_9step_50L=forecastfinal_9step-0.6745*GRforecast_9step_rmse

gen forecastfinal_10step=0.395381*x4_10+0.604619*x5_10
gen forecastfinal_10step_50U=forecastfinal_10step+0.6745*GRforecast_10step_rmse
gen forecastfinal_10step_50L=forecastfinal_10step-0.6745*GRforecast_10step_rmse

gen forecastfinal_11step=0.2787217*x4_11+0.7212783*x5_11
gen forecastfinal_11step_50U=forecastfinal_11step+0.6745*GRforecast_11step_rmse
gen forecastfinal_11step_50L=forecastfinal_11step-0.6745*GRforecast_11step_rmse

gen forecastfinal_12step=0.2620778*x4_12+0.7379222*x5_12
gen forecastfinal_12step_50U=forecastfinal_12step+0.6745*GRforecast_12step_rmse
gen forecastfinal_12step_50L=forecastfinal_12step-0.6745*GRforecast_12step_rmse

egen pointestimates=rowfirst(forecastfinal_1step forecastfinal_2step forecastfinal_3step forecastfinal_4step forecastfinal_5step forecastfinal_6step forecastfinal_7step forecastfinal_8step forecastfinal_9step forecastfinal_10step forecastfinal_11step forecastfinal_12step)

egen upperbound=rowfirst(forecastfinal_1step_50U forecastfinal_2step_50U forecastfinal_3step_50U forecastfinal_4step_50U forecastfinal_5step_50U forecastfinal_6step_50U forecastfinal_7step_50U forecastfinal_8step_50U forecastfinal_9step_50U forecastfinal_10step_50U forecastfinal_11step_50U forecastfinal_12step_50U)

egen lowerbound=rowfirst(forecastfinal_1step_50L forecastfinal_2step_50L forecastfinal_3step_50L forecastfinal_4step_50L forecastfinal_5step_50L forecastfinal_6step_50L forecastfinal_7step_50L forecastfinal_8step_50L forecastfinal_9step_50L forecastfinal_10step_50L forecastfinal_11step_50L forecastfinal_12step_50L)

replace hstart_can_new=. if time>tm(2019m12)
tsline hstart_can_new pointestimates upperbound lowerbound if time>tm(2019m1) &time<tm(2021m1), title(Housing Starts Forecast) lpattern(solid solid dash dash)

graph export beautiful.jpg,replace
//beautiful

