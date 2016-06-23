boost_factor <- function(base,m,n, x) {
  return(log(m*x+n, base=base))
}

base=exp(1)


n=base^0.1
m=(base^1-base^0.1)/0.5
boost_factor(base, m, n, 0.01)
