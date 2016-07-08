boost_factor <- function(base,m,n, x) {
  return(log(m*(1-x)+n, base=base))
}

base=exp(1)

# y1 is the weight when xapian prob is 100%
y1=0.8

# X2 is the xapian prob we want the boost factor to be 1
x2=0.75

n=base^y1
m=(base^1-n)/(1-x2)
boost_factor(base, m, n, 0)

sprintf('%.10f',m)
sprintf('%.10f',n)
