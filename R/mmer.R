mmer <- function (y, X = NULL, Z = NULL, W = NULL, R = NULL, method = "AI", 
          REML = TRUE, iters = 50, draw = FALSE, init = NULL, n.PC = 0, 
          P3D = TRUE, models = "additive", ploidy = 2, min.MAF = 0.05, 
          silent = FALSE, family = NULL, constraint = TRUE, sherman = FALSE, 
          MTG2 = FALSE){
  make.full <- function(X) {
    svd.X <- svd(X)
    r <- max(which(svd.X$d > 1e-08))
    return(as.matrix(svd.X$u[, 1:r]))
  }
  if (is.list(Z)) {
    if (is.list(Z[[1]])) {
      provided <- lapply(Z, names)
      for (s in 1:length(provided)) {
        provided2 <- names(Z[[s]])
        if (length(provided2) == 1) {
          if (provided2 == "K") {
            zz <- diag(length(y))
            Z[[s]] <- list(Z = zz, K = Z[[s]][[1]])
          }
          if (provided2 == "Z") {
            kk <- diag(dim(Z[[s]][[1]])[2])
            Z[[s]] <- list(Z = Z[[s]][[1]], K = kk)
          }
        }
        else {
          dido <- lapply(Z[[s]], dim)
          condi <- (dido$Z[2] == dido$K[1] & dido$Z[2] == 
                      dido$K[2])
          if (!condi) {
            cat(paste("ERROR! In the", s, "th random effect you have provided or created an incidence \nmatrix with dimensions:", 
                      dido$Z[1], "rows and", dido$Z[2], "columns. Therefore the \nvariance-covariance matrix(K) for this random effect expected was a \nsquare matrix with dimensions", 
                      dido$Z[2], "x", dido$Z[2]), ", but you provided a", 
                dido$K[1], "x", dido$K[2], " matrix \nas a variance-covariance matrix. Please double check your matrices.")
            stop()
          }
        }
      }
    }
    else {
      if (length(Z) == 1) {
        provided <- names(Z)
        if (provided == "K") {
          zz <- diag(length(y))
          Z <- list(Z = zz, K = Z[[1]])
        }
        if (provided == "Z") {
          kk <- diag(dim(Z[[1]])[2])
          Z <- list(Z = Z[[1]], K = kk)
        }
      }
      else {
        dido <- lapply(Z, dim)
        condi <- (dido$Z[2] == dido$K[1] & dido$Z[2] == 
                    dido$K[2])
        if (!condi) {
          cat(paste("ERROR! In the", s, "th random effect you have provided or created an incidence \nmatrix with dimensions:", 
                    dido$Z[1], "rows and", dido$Z[2], "columns. Therefore the \nvariance-covariance matrix(K) for this random effect expected was a \nsquare matrix with dimensions", 
                    dido$Z[2], "x", dido$Z[2]), ", but you provided a", 
              dido$K[1], "x", dido$K[2], " matrix \nas a variance-covariance matrix. Please double check your matrices.")
          stop()
        }
        else {
          Z = list(Z = Z)
        }
      }
    }
  }
  else {
    cat("\nThe parameter 'Z' needs to be provided in a 2-level list structure. \n\nPlease see help typing ?mmer and look at the 'Arguments' section\n")
    cat("\nIf no random effects provided, the model will be fitted using the 'lm' function\n\n")
  }
  Z <- lapply(Z, function(x) {
    im <- x[[1]]
    im <- apply(im, 2, function(y) {
      qq <- which(is.na(y))
      if (length(qq) > 0) {
        y[qq] <- median(y, na.rm = TRUE)
      }
      return(y)
    })
    z = list(Z = im, K = x[[2]])
    return(z)
  })
  if (is.list(Z)) {
    if (!is.null(Z) & !is.null(W)) {
      misso <- which(is.na(y))
      if (length(misso) > 0) {
        y[misso] <- mean(y, na.rm = TRUE)
      }
      if (is.null(colnames(W))) {
        colnames(W) <- paste("M", 1:dim(W)[2], sep = "-")
      }
      W <- apply(W, 2, function(x) {
        vv <- which(is.na(x))
        if (length(vv) > 0) {
          mu <- mean(x, na.rm = TRUE)
          x[vv] <- mu
        }
        else {
          x <- x
        }
      })
      cat("Estimating variance components\n")
      fixed <- which(unlist(lapply(Z, function(x) {
        names(x)[1]
      })) == "X")
      random <- which(unlist(lapply(Z, function(x) {
        names(x)[1]
      })) == "Z")
      random2 <- which(names(Z) == "Z")
      if (n.PC > 0) {
        KK <- A.mat(W, shrink = FALSE)
        eig.vec <- eigen(KK)$vectors
        if (is.null(X)) {
          X <- as.matrix(rep(1, dim(KK)[1]))
        }
        ZZ.comp <- list()
        for (i in 1:length(Z)) {
          X <- cbind(X, Z[[i]][[1]] %*% (1 + as.matrix(eig.vec[, 
                                                               1:n.PC])))
        }
        X <- make.full(X)
      }
      if (length(random) > 1 & method == "EMMA") {
        stop
        cat("\nError, The EMMA and GEMMA method were design to only deal with a single variance component other than error, please select method='AI' or method='EM' which can estimate more than one variance component\n\n")
      }
      if ((length(random) == 1 | length(random2) == 1) & 
          method == "EMMA") {
        if (length(random) > 0) {
          res <- EMMA(y = y, X = X, Z = Z[[random]][[1]], 
                      K = Z[[random]][[2]], REML = REML)
        }
        else {
          res <- EMMA(y = y, X = X, Z = Z[[1]], K = Z[[2]], 
                      REML = REML)
        }
      }
      if (method == "EM") {
        res <- EM(y = y, X = X, ETA = Z, R = R, init = init, 
                  iters = iters, REML = REML, draw = draw, silent = silent)
      }
      if (method == "AI") {
        res <- AI(y = y, X = X, ZETA = Z, R = R, REML = REML, 
                  draw = draw, silent = silent, iters = iters, 
                  constraint = constraint, init = init, sherman = sherman, 
                  che = FALSE, MTG2 = MTG2)
      }
      if (n.PC > 0) {
        X2 <- X
      }
      else {
        X2 <- make.full(res$X)
      }
      min.MAF = min.MAF
      n <- length(y)
      cat("\nPerforming GWAS")
      max.geno.freq = 1 - min.MAF
      W.scores <- list(NA)
      if (length(models) > 2) {
        layout(matrix(1:4, 2, 2))
      }
      else {
        layout(matrix(1:length(models), 1, length(models)))
      }
      for (u in 1:length(models)) {
        model <- models[u]
        cat(paste("\nRunning", model, "model"))
        ZO <- diag(dim(W)[1])
        step2 <- score.calc(marks = colnames(W), y = y, 
                            Z = ZO, X = X2, K = res$K, M = W, Hinv = res$V.inv, 
                            ploidy = ploidy, model = model, min.MAF = min.MAF, 
                            max.geno.freq = max.geno.freq)
        W.scores[[u]] <- step2$score
        plot(step2$score, col = transp("cadetblue", 0.6), 
             pch = 20, xlab = "Marker index", ylab = "-log10(p)", 
             main = paste(model, "model"), bty = "n", cex = 1.5)
      }
      names(W.scores) <- models
      res$W.scores <- W.scores
      res$method <- method
    }
  }
  if (is.list(Z)) {
    if ((!is.null(Z) & is.null(W))) {
      cat("Estimating variance components\n")
      fixed <- which(unlist(lapply(Z, function(x) {
        names(x)[1]
      })) == "X")
      random <- which(unlist(lapply(Z, function(x) {
        names(x)[1]
      })) == "Z")
      random2 <- which(names(Z) == "Z")
      if (length(random) > 1 & method == "EMMA") {
        stop
        cat("\nError, The EMMA and GEMMA method were design to only deal with a single variance component other than error, please select method='AI' or method='EM' which can estimate more than one variance component\n\n")
      }
      if ((length(random) == 1 | length(random2) == 1) & 
          method == "EMMA") {
        if (length(random) > 0) {
          res <- EMMA(y = y, X = X, Z = Z[[random]][[1]], 
                      K = Z[[random]][[2]], REML = REML)
        }
        else {
          res <- EMMA(y = y, X = X, Z = Z[[1]], K = Z[[2]], 
                      REML = REML)
        }
      }
      if (method == "EM") {
        res <- EM(y = y, X = X, ETA = Z, R = R, init = init, 
                  iters = iters, REML = REML, draw = draw, silent = silent)
      }
      if (method == "AI") {
        res <- AI(y = y, X = X, ZETA = Z, R = R, REML = REML, 
                  draw = draw, silent = silent, iters = iters, 
                  constraint = constraint, init = init, sherman = sherman, 
                  che = FALSE, MTG2 = MTG2)
      }
      res$method <- method
      res$maxim <- REML
    }
  }
  if ((is.null(X) & is.null(Z) & is.null(W))) {
    res <- lm(y ~ 1)
  }
  if ((!is.null(X) & is.null(Z) & is.null(W))) {
    res <- lm(y ~ X - 1)
  }
  class(res) <- c("mmer")
  layout(matrix(1, 1, 1))
  return(res)
}


"summary.mmer" <- function(object, ...) {
  digits = max(3, getOption("digits") - 3)
  groupss <- unlist(lapply(object$u.hat, function(y){dim(y)[1]}))
  groupss <- paste(groupss,collapse = " ")
  nn <- length(unlist(object$residuals))
  #cat("Linear mixed model fit by restricted maximum likelihood\n")
  #cat("=======================================================")
  #cat("\nMethod:")
  #print(object$method)
  method=object$method
  #cat("\n")
  
  logo <- c(logLik = object$LL, AIC=object$AIC, BIC=object$BIC)
  names(logo) = c("logLik","AIC","BIC")
  #print(c(logo), digits = digits)
  
  #cat("=======================================================")
  #cat("\nRandom effects:\n")
  w <- data.frame(VarianceComp = matrix(c(object$var.comp), ncol = 1))
  
  if(object$method == "EM"){
    row.names(w) <- rownames(object$var.comp)
  }
  if(object$method == "AI" | object$method == "EMMA"){
    row.names(w) <- rownames(object$var.comp)
  }
  #print(w, digits = digits)
  #cat(paste("Number of obs:",nn," Groups:",groupss,"\n"))
  
  #cat("=======================================================")
  #cat("\nFixed effects:\n")
  coef <- data.frame(Value = as.matrix(object$beta.hat), Std.Error=(matrix(sqrt(diag(object$Var.beta.hat)),ncol=1)), t.value=(matrix((object$beta.hat-0)/sqrt(diag(object$Var.beta.hat)), ncol=1)))
  if(dim(coef)[1] == 1){rownames(coef) <- "Intercept"}
  #printCoefmat((coef))
  #cat("=======================================================")
  #cat("\nVar-Cov for Fixed effects:\n")
  varbhat <- data.frame(as.matrix(object$Var.beta.hat))
  rownames(varbhat) <- colnames(object$X)
  colnames(varbhat) <- rownames(varbhat) 
  if(dim(varbhat)[1] == 1){rownames(varbhat) <- "Intercept"}
  #printCoefmat(varbhat)
  #cat("=======================================================")
  #cat("\nInformation contained in this fitted model: \n* Variance components\n* Residuals and conditional residuals\n* Inverse phenotypic variance(V)\* BLUEs and BLUPs\n* Variance-covariance matrix for fixed effects\n* Variance-covariance matrix for random effects\n* Predicted error variance (PEV)\n* LogLikelihood\n* AIC and BIC\n* Fitted values\nUse the 'str' function to access such information")
  output <- list(groupss=groupss, nn=nn, logo=logo, w=w, coef=coef, varbhat=varbhat, method=method)
  attr(output, "class")<-c("summary.mmer", "list")
  return(output)
}

"print.summary.mmer"<-function (x, digits = max(3, getOption("digits") - 3),  ...){
  digits = max(3, getOption("digits") - 3)
  #groupss <- unlist(lapply(x$u.hat, function(y){dim(y)[1]}))
  #groupss <- paste(groupss,collapse = " ")
  #nn <- length(unlist(x$residuals))
  cat("\nInformation contained in this fitted model: \n* Variance components\n* Residuals and conditional residuals\n* BLUEs and BLUPs\n* Inverse phenotypic variance(V)\n* Variance-covariance matrix for fixed effects\n* Variance-covariance matrix for random effects\n* Predicted error variance (PEV)\n* LogLikelihood\n* AIC and BIC\n* Fitted values\nUse the 'str' function to access such information\n")
  cat("\n=======================================================")
  cat("\nLinear mixed model fit by restricted maximum likelihood\n")
  cat("********************  sommer 1.2  *********************\n")
  cat("=======================================================")
  cat("\nMethod:")
  print(x$method)
  cat("\n")
  
  #logo <- c(logLik = x$LL, AIC=x$AIC, BIC=x$BIC)
  #names(logo) = c("logLik","AIC","BIC")
  print(c(x$logo), digits = digits)
  
  cat("=======================================================")
  cat("\nRandom effects:\n")
  #w <- data.frame(VarianceComp = matrix(c(x$var.comp), ncol = 1))
  
  #if(x$method == "EM"){
  #  row.names(w) <- names(x$var.comp)
  #}
  #if(x$method == "AI" | x$method == "EMMA"){
  #  row.names(w) <- rownames(x$var.comp)
  #}
  print(x$w, digits = digits)
  cat(paste("Number of obs:",x$nn," Groups:",x$groupss,"\n"))
  
  cat("=======================================================")
  cat("\nFixed effects:\n")
  #coef <- data.frame(Value = x$beta.hat, Std.Error=(matrix(sqrt(diag(x$Var.beta.hat)),ncol=1)), t.value=(matrix((x$beta.hat-0)/sqrt(diag(x$Var.beta.hat)), ncol=1)))
  #if(dim(coef)[1] == 1){rownames(coef) <- "Intercept"}
  printCoefmat((x$coef))
  cat("=======================================================")
  cat("\nVar-Cov for Fixed effects:\n")
  #varbhat <- data.frame(x$Var.beta.hat)
  #colnames(varbhat) <- rownames(varbhat) 
  #if(dim(varbhat)[1] == 1){rownames(varbhat) <- "Intercept"}
  printCoefmat(x$varbhat)
  cat("=======================================================")
  cat("\nUse the 'str' function to have access to all information\n\n")
}

"residuals.mmer" <- function(object, type="conditional", ...) {
  digits = max(3, getOption("digits") - 3)
  if(type=="conditional"){
    output<-round(object$cond.residuals,digits)
  }else{
    output<-round(object$residuals,digits)
  }
  return(output)
}

"print.residuals.mmer"<- function(x, digits = max(3, getOption("digits") - 3), ...) {
  print((x))
}



"randef" <- function(object) {
  digits = max(3, getOption("digits") - 3)
  output <- object$u.hat
  return(output)
}

"fixef.mmer" <- function(object, ...) {
  digits = max(3, getOption("digits") - 3)
  output <- object$beta.hat
  return(output)
}

"print.fixef.mmer"<- function(x, digits = max(3, getOption("digits") - 3), ...) {
  print((x))
}


"fitted.mmer" <- function(object, type="complete", ...) {
  #type="complete" 
  digits = max(3, getOption("digits") - 3)
  if(type=="complete"){
    round(object$fitted.y,digits)
  }else{
    round(object$fitted.u,digits)
  }
}

"print.fitted.mmer"<- function(x, digits = max(3, getOption("digits") - 3), ...) {
  print((x))
} 


"coef.mmer" <- function(object, ...){
  object$beta.hat
}

"print.coef.mmer"<- function(x, digits = max(3, getOption("digits") - 3), ...) {
  print((x))
} 


anova.mmer <- function(object, object2=NULL, ...) {
  signifo <- function(x){
    if(x >= 0 & x < 0.001){y="***"}
    if(x >= 0.001 & x < 0.01){y="**"}
    if(x >= 0.01 & x < 0.05){y="*"}
    if(x >= 0.05 & x < 0.1){y="."}
    if(x > 0.1){y=""}
    return(y)
  }
  ########################################
  digits = max(3, getOption("digits") - 3)
  if(is.null(object2)){
    stop("The 'anova' function for the sommer package only works to compare mixed models by likelihood ratio tests (LRT), was not intended to provide regular sum of squares output.")
  }else{
    if(object$maxim){ # user used REML=TRUE, not possible to do LRT
      stop("Please fit the models using ML instead of REML by setting the argument REML=FALSE and try again")
    }else{ #if user used REML=FALSE, then proceed
      if(object$method != object2$method){
        stop("Error! When comparing models please use the same method for the fitted models.")
      }else{
        dis=c(dim(as.matrix(object$var.comp))[1]+dim(object$beta.hat)[1],
              dim(as.matrix(object2$var.comp))[1]+dim(object2$beta.hat)[1]) # dimensions
        mods=c("mod1","mod2")
        lls=c(object$LL, object2$LL) # likelihoods
        aics=c(object$AIC, object2$AIC) # AIC's
        bics=c(object$BIC, object2$BIC) # AIC's
        vv=which(dis == max(dis))[1] # which has more variance components BIGGER
        vv2=c(1:2)[which(c(1:2)!= vv)] # SMALLER
        LR = (lls[vv] - lls[vv2])
        r.stat= abs(-2*((LR))) # -2(LL1 - LL2)
        df=dis[vv]-dis[vv2]
        chichi=round(pchisq((r.stat), df, lower.tail=FALSE),16)
        chichi2=paste(as.character((chichi)),signifo(chichi), sep=" ")
        ### construct the table
        cat("Likelihood ratio test for mixed models\n")
        cat("==============================================================\n")
        result=data.frame(Df=c(dis[vv],dis[vv2]), AIC=c(aics[vv],aics[vv2]), 
                          BIC=c(bics[vv],bics[vv2]), loLik=c(lls[vv],lls[vv2]), 
                          Chisq=c("",as.character(round(r.stat,5))), 
                          ChiDf=c("",as.character(df)), PrChisq=c("",as.character(chichi2 )))
        rownames(result) <- c(mods[vv],mods[vv2])
        print(result)
        cat("==============================================================\n")
        cat("Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1")
      }
    }
  }
}


plot.mmer <- function(x, ...) {
  digits = max(3, getOption("digits") - 3)
  transp <- function (col, alpha = 0.5){
    res <- apply(col2rgb(col), 2, function(c) rgb(c[1]/255, c[2]/255,c[3]/255, alpha))
    return(res)
  }
  # std vs residuals, QQplot (std vs teor quantiles), sqrt(std residuals) vs fitted, std res vs leverage = cook's distance
  layout(matrix(1:4,2,2))
  plot(x$fitted.y.good, scale(x$cond.residuals), pch=20, col=transp("cadetblue"), ylab="Std Residuals", xlab="Fitted values", main="Residual vs Fitted", bty="n", ...); grid()
  plot(x$fitted.y.good, sqrt(abs((scale(x$cond.residuals)))), pch=20, col=transp("thistle4"), ylab="Sqrt Abs Std Residuals", xlab="Fitted values", main="Scale-Location",bty="n", ...);grid()
  qqnorm(scale(x$cond.residuals), pch=20, col=transp("tomato1"), ylab="Std Residuals", bty="n",...); grid()
  hat <- x$X%*%solve(t(x$X)%*%x$V.inv%*%x$X)%*%t(x$X)%*%x$V.inv # leverage including variance from random effects H= X(X'V-X)X'V-
  plot(diag(hat), scale(x$cond.residuals), pch=20, col=transp("springgreen3"), ylab="Std Residuals", xlab="Leverage", main="Residual vs Leverage", bty="n", ...); grid()
  #####################
  layout(matrix(1,1,1))
}



#this function is executed once the library is loaded
.onAttach = function(library, pkg)
{
  Rv = R.Version()
  if(!exists("getRversion", baseenv()) || (getRversion() < "2.1"))
    stop("This package requires R 2.1 or later")
  assign(".sommer.home", file.path(library, pkg),
         pos=match("package:sommer", search()))
  sommer.version = "1.2 (2016-03-01)"
  assign(".sommer.version", sommer.version, pos=match("package:sommer", search()))
  if(interactive())
  {
    packageStartupMessage(paste("## ========================================================= ## "),appendLF=TRUE)
    packageStartupMessage(paste("# Solving Mixed Model Equations in R (sommer) ", sommer.version, ". ",sep=""),appendLF=TRUE)
    packageStartupMessage(paste("# Mixed models allowing covariance structures in random effects"),appendLF=TRUE)
    packageStartupMessage("# Author: Giovanny Covarrubias-Pazaran",appendLF=TRUE)
    packageStartupMessage("# Supported by the Council of Science and Technology (CONACYT)", appendLF=TRUE)
    packageStartupMessage("# Type 'help(sommer)' for summary information",appendLF=TRUE)
    packageStartupMessage(paste("## ========================================================= ## "),appendLF=TRUE)
  }
  invisible()
}