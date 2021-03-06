#' @title Cross Validation for glmmLasso package
#' @description Cross Validation for glmmLasso package as shown in example xxx
#' @param dat data.frame, containing y,X,Z and subject variables
#' @param form.fixed formaula, fixed param formula, Default: NULL
#' @param form.rnd list, named list containing random effect formula, Default: NULL
#' @param lambda numeric, vector containing lasso penalty levels, Default: seq(500, 0, by = -5)
#' @param family family, family function that defines the distribution link of the glmm, Default: gaussian(link = "identity")
#' @return list of a fitted glmmLasso object and the cv BIC path
#' @examples
#' \dontrun{cv.glmmLasso(initialize_example(seed=1))}
#' @references A. Groll and G. Tutz. Variable selection for generalized linear mixed models by L1-penalized estimation. 
#'  Statistics and Computing, pages 1–18, 2014.
#'  
#'  \href{https://raw.githubusercontent.com/cran/glmmLasso/master/demo/glmmLasso-soccer.r}{cv function is the generalized form of last example glmmLasso package demo file}
#'  
#' @seealso 
#'  \code{\link[glmmLasso]{glmmLasso}}
#' @rdname cv.glmmLasso
#' @export 
#' @importFrom glmmLasso glmmLasso
#' @importFrom stats gaussian as.formula
cv.glmmLasso=function(dat,
                      form.fixed=NULL,
                      form.rnd=NULL,
                      lambda=seq(500,0,by=-5),
                      family=stats::gaussian(link = "identity")
                      ){
  
  if(inherits(dat,'matrix')) dat <- as.data.frame(dat)
    
  d.size=(max(as.numeric(row.names(dat)))*(sum(grepl('^Z',names(dat)))+1))+(sum(grepl('^X',names(dat)))+1)
  
  dat<-data.frame(subject=as.factor(row.names(dat)),dat,check.names = FALSE,row.names = NULL)
  
  if(is.null(form.fixed)) form.fixed<-sprintf('y~%s',paste(grep('^X',names(dat),value = TRUE),collapse = '+'))
  if(is.null(form.rnd)) form.rnd<-eval(parse(text=sprintf('form.rnd<-list(subject=~1+%s)',paste(grep('^Z',names(dat),value = TRUE),collapse = '+'))))
  
  BIC_vec<-rep(Inf,length(lambda))
  
  # specify starting values for the very first fit; pay attention that Delta.start has suitable length! 
  
  Delta.start.base<-Delta.start<-as.matrix(t(rep(0,d.size)))
  Q.start.base<-Q.start<-0.1  
  
  for(j in 1:length(lambda))
  {
    suppressMessages({
      suppressWarnings({
        fn <- try(glmmLasso::glmmLasso(fix = stats::as.formula(form.fixed),
                                       rnd = form.rnd,
                                       data = dat,lambda = lambda[j],
                                       switch.NR = FALSE,final.re=TRUE,
                                       control = list(start=Delta.start[j,],q.start=Q.start[j]))      
        )
      })      
    })
    
    if(class(fn)!="try-error")
    {  
      BIC_vec[j]<-fn$bic
      Delta.start<-rbind(Delta.start,fn$Deltamatrix[fn$conv.step,])
      Q.start<-c(Q.start,fn$Q_long[[fn$conv.step+1]])
    }else{
      Delta.start<-rbind(Delta.start,Delta.start.base)
      Q.start<-c(Q.start,Q.start.base)
    }
  }
  
    opt<-which.min(BIC_vec)
  
    suppressWarnings({
    final <- glmmLasso::glmmLasso(fix = as.formula(form.fixed), rnd = form.rnd,
                                  data = dat, lambda=lambda[opt],switch.NR=FALSE,final.re=TRUE,
                                  control = list(start=Delta.start[opt,],q_start=Q.start.base))
    
    final
  })
  
  list(fit.opt=final,BIC_path=BIC_vec)
}  
