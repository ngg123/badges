#
# Implementation of Perceptron and Winnow Machine Learning Algorithms
#

#
# This is pseudo-vectorized: It will work is x and ws are lists, or 
# if x is a n x m matrix and ws is a m x 1 column vector, or if
# x is a 1 x m row vector and ws is a m x 1 column vector
#
# But, really, we probably shouldn't be making lots of predictions 
# between updates.
#
predict.hyper <- function(ws,x,thresh=0) x%*%ws>thresh

perceptron.update <- function(ws,x,y,RATE=0.1){
  good.pred <- predict.hyper(ws,x) == y
  ws + 
    (!good.pred)*RATE*
    sign(y-(!y))*#only predict -1 or +1 for any numeric or logical input
    x
}

winnow.promote <- function(ws,x,RATE=2) ws + ws*x

winnow.demote <- function(ws,x,RATE=2) ws - ws*x/2

winnow.update <- function(ws,x,y,RATE=2){
  good.pred <- predict.hyper(ws,x,thresh=length(ws))==y
  ws*good.pred + 
    (!good.pred)*(y > 0)*winnow.promote(ws,x,RATE) + 
    (!good.pred)*(y <= 0)*winnow.demote(ws,x,RATE)
}


bwinn.update <- function(wspn,x,y,RATE=2){
  wsp <- wspn$p
  wsn <- wspn$n
  
}