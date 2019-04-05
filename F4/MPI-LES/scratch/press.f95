subroutine press(u,v,w,p,rhs,f,g,h,dx1,dy1,dzn,dxs,dys,dzs,dt,n,nmax)
      integer, parameter :: kp = 80 
      integer, parameter :: ip = 300 
      integer, parameter :: jp = 300 
      integer, parameter :: ipmax = 300 
      integer, parameter :: jpmax = 300 
      character*300 :: datafile = '../GIS/Kyoto_1km2_4m_with_buffer.txt' 
      real, parameter :: dxgrid = 4. 
      real, parameter :: dygrid = 4. 
      real, parameter :: cs0 = 0.14 
      integer, parameter :: i_anime = 1 
      integer, parameter :: avetime = 2 
      integer, parameter :: km_sl = 80 
      integer, parameter :: i_aveflow = 0 
      integer, parameter :: i_ifdata_out = 0 
      real, parameter :: dt_orig = 0.05 
      real(4), dimension(0:300), intent(In) :: dxs
      real(4), dimension(0:300), intent(In) :: dys
      real(4), dimension(-1:82), intent(In) :: dzs
      real(4) :: cn1,cn2l,cn2s,cn3l,cn3s,cn4l,cn4s,dz1,dz2
      real(4), intent(In) :: dt
      real(4), dimension(-1:301), intent(In) :: dx1
      real(4), dimension(0:301), intent(In) :: dy1
      real(4), dimension(-1:82), intent(In) :: dzn
      real(4), dimension(0:300,0:300,0:80), intent(InOut) :: f
      real(4), dimension(0:300,0:300,0:80), intent(InOut) :: g
      real(4), dimension(0:300,0:300,0:80), intent(InOut) :: h
      integer, intent(In) :: n
      integer, intent(In) :: nmax
      real(4), dimension(0:1,0:302,0:302,0:81) :: p
      real(4), dimension(0:301,0:301,0:81), intent(Out) :: rhs
      real(4), dimension(0:301,-1:301,0:81), intent(In) :: u
      real(4), dimension(0:301,-1:301,0:81), intent(In) :: v
      real(4), dimension(0:301,-1:301,-1:81), intent(In) :: w
      integer :: nn
      integer :: i,j,k,l,nrd
      real(4) :: rhsav,pav,area,pco,sor,reltmp
      real, parameter :: pjuge = 0.0001 
      integer, parameter :: nmaxp = 50 
      real, parameter :: omega = 1. 
      integer :: synthIdx0
      integer :: synthIdx1
      integer :: synthIdx2
      integer :: synthIdx3
    do k = 1, 80, 1
        do j = 1, 300, 1
            do i = 1, 300, 1
                rhs(i,j,k) = (-u(i-1,j,k)+u(i,j,k))/dx1(i)+(-v(i,j-1,k)+v(i,j,k))/dy1(j)+(-w(i,j,k-1)+w(i,j,k))/dzn(k)
                rhs(i,j,k) = (f(i,j,k)-f(i-1,j,k))/dx1(i)+(g(i,j,k)-g(i,j-1,k))/dy1(j)+(h(i,j,k)-h(i,j,k-1))/dzn(k)+rhs(i,j,k)/dt
            end do
        end do
    end do
    rhsav = 0.0
    area = 0.0
    do k = 1, 80, 1
        do j = 1, 300, 1
            do i = 1, 300, 1
                rhsav = rhsav+dx1(i)*dy1(j)*dzn(k)*rhs(i,j,k)
                area = area+dx1(i)*dy1(j)*dzn(k)
            end do
        end do
    end do
    rhsav = rhsav/area
    do k = 1, 80, 1
        do j = 1, 300, 1
            do i = 1, 300, 1
                rhs(i,j,k) = rhs(i,j,k)-rhsav
            end do
        end do
    end do
    do l = 1, 50, 1
        sor = 0.0
        do nrd = 0, 1, 1
            do k = 1, 80, 1
                do j = 1, 300, 1
                    do i = 1, 300, 1
                        do synthIdx3 = 0, 1, 1
                            dz1 = dzs(k-1)
                            dz2 = dzs(k)
                            cn4s = 2./(dz1*(dz1+dz2))
                            cn4l = 2./(dz2*(dz1+dz2))
                            cn3s = 2./(dys(j-1)*(dys(j-1)+dys(j)))
                            cn3l = 2./(dys(j)*(dys(j-1)+dys(j)))
                            cn2s = 2./(dxs(i-1)*(dxs(i-1)+dxs(i)))
                            cn2l = 2./(dxs(i)*(dxs(i-1)+dxs(i)))
                            cn1 = 1./(2./(dxs(i-1)*dxs(i))+2./(dys(j-1)*dys(j))+2./(dz1*dz2))
                            if (nrd==0) then
                                if (synthIdx3==1) then
                                    reltmp = 1.0*(cn1*(cn2l*p(synthIdx3-1,i+1,j,k)+cn2s*p(synthIdx3-1,i-1,j,k)+cn3l*p(synthIdx3-1,i,j+1,k)+cn3s*p(synthIdx3-1,i,j-1,k)+cn4l*p(synthIdx3-1,i,j,k+1)+cn4s*p(synthIdx3-1,i,j,k-1)-rhs(i,j,k))-p(synthIdx3-1,i,j,k))
                                    p(synthIdx3,i,j,k) = p(synthIdx3-1,i,j,k)+reltmp
                                end if
                            else
                                if (synthIdx3==0) then
                                    reltmp = 1.0*(cn1*(cn2l*p(synthIdx3+1,i+1,j,k)+cn2s*p(synthIdx3+1,i-1,j,k)+cn3l*p(synthIdx3+1,i,j+1,k)+cn3s*p(synthIdx3+1,i,j-1,k)+cn4l*p(synthIdx3+1,i,j,k+1)+cn4s*p(synthIdx3+1,i,j,k-1)-rhs(i,j,k))-p(synthIdx3+1,i,j,k))
                                    p(synthIdx3,i,j,k) = p(synthIdx3+1,i,j,k)+reltmp
                                end if
                            end if
                        end do
                    end do
                end do
            end do
            do k = 0, 81, 1
                do j = 0, 301, 1
                    do synthIdx2 = 0, 302, 1
                        do synthIdx3 = 0, 1, 1
                            if (synthIdx2==0 .and. synthIdx3==0) then
                                p(synthIdx3,synthIdx2,j,k) = p(synthIdx3,synthIdx2+1,j,k)
                            end if
                            if (synthIdx3==0 .and. synthIdx2==301) then
                                p(synthIdx3,synthIdx2,j,k) = p(synthIdx3,synthIdx2-1,j,k)
                            end if
                        end do
                    end do
                end do
            end do
            do k = 0, 81, 1
                do synthIdx1 = 0, 302, 1
                    do i = 0, 301, 1
                        do synthIdx3 = 0, 1, 1
                            if (synthIdx1==0 .and. synthIdx3==0) then
                                p(synthIdx3,i,synthIdx1,k) = p(synthIdx3,i,synthIdx1+300,k)
                            end if
                            if (synthIdx3==0 .and. synthIdx1==301) then
                                p(synthIdx3,i,synthIdx1,k) = p(synthIdx3,i,synthIdx1-300,k)
                            end if
                        end do
                    end do
                end do
            end do
        end do
        do synthIdx0 = 0, 81, 1
            do j = 0, 301, 1
                do i = 0, 301, 1
                    do synthIdx3 = 0, 1, 1
                        if (synthIdx0==0 .and. synthIdx3==0) then
                            p(synthIdx3,i,j,synthIdx0) = p(synthIdx3,i,j,synthIdx0+1)
                        end if
                        if (synthIdx3==0 .and. synthIdx0==81) then
                            p(synthIdx3,i,j,synthIdx0) = p(synthIdx3,i,j,synthIdx0-1)
                        end if
                    end do
                end do
            end do
        end do
    end do
    pav = 0.0
    pco = 0.0
    do k = 1, 80, 1
        do j = 1, 300, 1
            do i = 1, 300, 1
                do synthIdx3 = 0, 1, 1
                    if (synthIdx3==0) then
                        pav = pav+p(synthIdx3,i,j,k)*dx1(i)*dy1(j)*dzn(k)
                        pco = pco+dx1(i)*dy1(j)*dzn(k)
                    end if
                end do
            end do
        end do
    end do
    pav = pav/pco
    do k = 1, 80, 1
        do j = 1, 300, 1
            do i = 1, 300, 1
                do synthIdx3 = 0, 1, 1
                    if (synthIdx3==0) then
                        p(synthIdx3,i,j,k) = p(synthIdx3,i,j,k)-pav
                    end if
                end do
            end do
        end do
    end do
    do k = 0, 81, 1
        do j = 0, 301, 1
            do synthIdx2 = 0, 302, 1
                do synthIdx3 = 0, 1, 1
                    if (synthIdx2==0 .and. synthIdx3==0) then
                        p(synthIdx3,synthIdx2,j,k) = p(synthIdx3,synthIdx2+1,j,k)
                    end if
                    if (synthIdx3==0 .and. synthIdx2==301) then
                        p(synthIdx3,synthIdx2,j,k) = p(synthIdx3,synthIdx2-1,j,k)
                    end if
                end do
            end do
        end do
    end do
    do k = 0, 81, 1
        do synthIdx1 = 0, 302, 1
            do i = 0, 301, 1
                do synthIdx3 = 0, 1, 1
                    if (synthIdx1==0 .and. synthIdx3==0) then
                        p(synthIdx3,i,synthIdx1,k) = p(synthIdx3,i,synthIdx1+300,k)
                    end if
                    if (synthIdx3==0 .and. synthIdx1==301) then
                        p(synthIdx3,i,synthIdx1,k) = p(synthIdx3,i,synthIdx1-300,k)
                    end if
                end do
            end do
        end do
    end do
    do synthIdx0 = 0, 81, 1
        do j = 0, 301, 1
            do i = 0, 301, 1
                do synthIdx3 = 0, 1, 1
                    if (synthIdx0==0 .and. synthIdx3==0) then
                        p(synthIdx3,i,j,synthIdx0) = p(synthIdx3,i,j,synthIdx0+1)
                    end if
                    if (synthIdx3==0 .and. synthIdx0==81) then
                        p(synthIdx3,i,j,synthIdx0) = p(synthIdx3,i,j,synthIdx0-1)
                    end if
                end do
            end do
        end do
    end do
end subroutine press
