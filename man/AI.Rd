\name{AI}
\alias{AI}
\title{Average Information Algorithm}
\description{
Univariate version of the Average information (AI) algorithm.
}
\usage{
AI(y,X=NULL,ZETA=NULL,R=NULL,iters=30,draw=TRUE,silent=FALSE, 
    constraint=TRUE, init=NULL, forced=NULL,tolpar = 1e-04, 
    tolparinv = 1e-06)
}
\arguments{
  \item{y}{a numeric vector for the response variable}
  \item{X}{an incidence matrix for fixed effects.}
  \item{ZETA}{an incidence matrix for random effects. This can be for one or more random effects. This NEEDS TO BE PROVIDED AS A LIST STRUCTURE. For example Z=list(list(Z=Z1, K=K1), list(Z=Z2, K=K2), list(Z=Z3, K=K3)) makes a 2 level list for 3 random effects. The general idea is that each random effect with or without its variance-covariance structure is a list, i.e. list(Z=Z1, K=K1) where Z is the incidence matrix and K the var-cov matrix. When moving to more than one random effect we need to make several lists that need to be inside another list. What we call a 2-level list, i.e. list(Z=Z1, K=K1) and list(Z=Z2, K=K2) would need to be put in the form; list(list(Z=Z1, K=K1),list(Z=Z1, K=K1)), which as can be seen, is a list of lists (2-level list). }
  \item{R}{a matrix for variance-covariance structures for the residuals, i.e. for longitudinal data. if not passed is assumed an identity matrix.}
  \item{iters}{a scalar value indicating how many iterations have to be performed if the EM is performed. There is no rule of tumb for the number of iterations. The default value is 100 iterations or EM steps.}
  \item{draw}{a TRUE/FALSE value indicating if a plot of updated values for the variance components and the likelihood should be drawn or not. The default is TRUE. COMPUTATION TIME IS SMALLER IF YOU DON'T PLOT SETTING draw=FALSE}
  \item{silent}{a TRUE/FALSE value indicating if the function should draw the progress bar or iterations performed while working or should not be displayed.}
  \item{constraint}{a TRUE/FALSE value indicating if the program should use the boundary constraint when one or more variance component is close to the zero boundary. The default is TRUE but needs to be used carefully. It works ideally when few variance components are close to the boundary but when there are too many variance components close to zero we highly recommend setting this parameter to FALSE since is more likely to get the right value of the variance components in this way.}
   \item{init}{vector of initial values for the variance components. By default this is NULL and variance components are estimated by the method selected, but in case the user want to provide initial values this argument is functional.}
   \item{forced}{a vector of numeric values for variance components including error if the user wants to force the values of the variance components. On the meantime only works for forcing all of them and not a subset of them. The default is NULL, meaning that variance components will be estimated by REML/ML.}
   \item{tolpar}{tolerance parameter for convergence in the models.}
   \item{tolparinv}{tolerance parameter for matrix inversion in the models.}
}
\details{
This algorithm is based on Gilmour et al. (1995). 
}
\value{
If all parameters are correctly indicated the program will return a list with the following information:
\describe{
\item{$Vu}{a scalar value for the variance component estimated}
\item{$Ve}{a scalar value for the error variance estimated}
\item{$V.inv}{a matrix with the inverse of the phenotypic variance V = ZGZ+R, V^-1}
\item{$u.hat}{a vector with BLUPs for random effects}
\item{$Var.u.hat}{a vector with variances for BLUPs}
\item{$PEV.u.hat}{a vector with predicted error variance for BLUPs}
\item{$beta.hat}{a vector for BLUEs of fixed effects}
\item{$Var.beta.hat}{a vector with variances for BLUEs}
\item{$X}{incidence matrix for fixed effects, if not passed is assumed to only include the intercept}
\item{$Z}{ incidence matrix for random effects, if not passed is assumed to be a diagonal matrix}
\item{$K}{ the var-cov matrix for the random effect fitted in Z}
\item{$ll}{ the log-likelihood value for obtained when optimizing the likelihood function when using ML or REML}
}
}
\references{
Covarrubias-Pazaran G (2016) Genome assisted prediction of quantitative traits using the R package sommer. PLoS ONE 11(6): doi:10.1371/journal.pone.0156744 
Gilmour et al. 1995. Average Information REML: An efficient algorithm for variance parameter estimation in linear mixed models. Biometrics 51(4):1440-1450.
}
\examples{
####=========================================####
#### For CRAN time limitations most lines in the 
#### examples are silenced with one '#' mark, 
#### remove them and run the examples
####=========================================####

####=========================================####
#### breeding values with 3 variance components
####=========================================####

####=========================================####
## Import phenotypic data on inbred performance
## Full data
####=========================================####
data(cornHybrid)
hybrid2 <- cornHybrid$hybrid # extract cross data
A <- cornHybrid$K # extract the var-cov K

y <- hybrid2$Yield
X1 <- model.matrix(~ Location, data = hybrid2);dim(X1)
Z1 <- model.matrix(~ GCA1 -1, data = hybrid2);dim(Z1)
Z2 <- model.matrix(~ GCA2 -1, data = hybrid2);dim(Z2)
Z3 <- model.matrix(~ SCA -1, data = hybrid2);dim(Z3)

####=========================================####
#### Realized IBS relationships for set of parents 1
####=========================================####
K1 <- A[levels(hybrid2$GCA1), levels(hybrid2$GCA1)]; dim(K1)     
####=========================================####
#### Realized IBS relationships for set of parents 2
####=========================================####
K2 <- A[levels(hybrid2$GCA2), levels(hybrid2$GCA2)]; dim(K2)     
####=========================================####
#### Realized IBS relationships for cross 
#### (as the Kronecker product of K1 and K2)
####=========================================####
S <- kronecker(K1, K2) ; dim(S)   
rownames(S) <- colnames(S) <- levels(hybrid2$SCA)

ETA <- list(list(Z=Z1, K=K1), list(Z=Z2, K=K2), list(Z=Z3, K=S))
####=========================================####
#### run the next line, it was ommited for CRAN time limitations
####=========================================####
#ans <- AI(y=y, ZETA=ETA)
#ans$var.comp
}
\seealso{The core functions of the package \code{\link{mmer}} and \code{\link{mmer2}}}