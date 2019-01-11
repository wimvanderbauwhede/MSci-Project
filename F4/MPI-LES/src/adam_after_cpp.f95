module module_adam
 contains
subroutine adam(n,nmax,data21,fold,gold,hold,&
f,g,h)
      implicit none
    character(len=70), intent(In) :: data21
    real(kind=4), dimension(0:ip,0:jp,0:kp) , intent(InOut) :: f
    real(kind=4), dimension(0:ip,0:jp,0:kp) , intent(InOut) :: g
    real(kind=4), dimension(0:ip,0:jp,0:kp) , intent(InOut) :: h
    real(kind=4), dimension(ip,jp,kp) , intent(InOut) :: fold
    real(kind=4), dimension(ip,jp,kp) , intent(InOut) :: gold
    real(kind=4), dimension(ip,jp,kp) , intent(InOut) :: hold
    integer, intent(In) :: n
    integer, intent(In) :: nmax
    integer :: i,j,k
    real(kind=4) :: fd,gd,hd
    do k = 1,kp
        do j = 1,jp
            do i = 1,ip
                fd = f(i,j,k)
                gd = g(i,j,k)
                hd = h(i,j,k)
                f(i,j,k) = 1.5*f(i,j,k)-0.5*fold(i,j,k)
                g(i,j,k) = 1.5*g(i,j,k)-0.5*gold(i,j,k)
                h(i,j,k) = 1.5*h(i,j,k)-0.5*hold(i,j,k)
                fold(i,j,k) = fd
                gold(i,j,k) = gd
                hold(i,j,k) = hd
            end do
        end do
    end do
end subroutine adam
end module module_adam