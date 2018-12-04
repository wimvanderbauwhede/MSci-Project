--------------------------------------------------------------------------------
dyn
--------------------------------------------------------------------------------
subroutine dyn(j,k,dx,g,eta,dt,dy,un,u,wet,v,vn,h,etan)
      integer(4), parameter :: ny = 500 
      integer(4), parameter :: nx = 500 
      integer :: j
      integer :: k
      real, intent(In) :: dx
      real, intent(In) :: g
      real, dimension(0:ny+1,0:nx+1) :: eta
      real, intent(In) :: dt
      real, intent(In) :: dy
      real, dimension(0:ny+1,0:nx+1), intent(InOut) :: un
      real, dimension(0:ny+1,0:nx+1), intent(In) :: u
      integer, dimension(0:ny+1,0:nx+1), intent(In) :: wet
      real, dimension(0:ny+1,0:nx+1), intent(In) :: v
      real, dimension(0:ny+1,0:nx+1), intent(InOut) :: vn
      real, dimension(0:ny+1,0:nx+1), intent(In) :: h
      real, dimension(0:ny+1,0:nx+1) :: etan
      real, dimension(0:ny+1,0:nx+1) :: du
      real, dimension(0:ny+1,0:nx+1) :: dv
      real :: uu
      real :: vv
      real :: duu
      real :: dvv
      real :: hue
      real :: huw
      real :: hwp
      real :: hwn
      real :: hen
      real :: hep
      real :: hvn
      real :: hvs
      real :: hsp
      real :: hsn
      real :: hnn
      real :: hnp
! OpenCLMap ( ["dt","g","dx","dy"],["du","dv"],["(j,1,500.0,1)","(k,1,500.0,1)"],[]) {
! OpenCLMap ( ["dt","g","dx","dy"],["du","dv"],["(k,1,500.0,1)"],[]) {
    du(j,k) = -dt*g*(eta(j,k+1)-eta(j,k))/dx
    dv(j,k) = -dt*g*(eta(j+1,k)-eta(j,k))/dy
    }
    }
! OpenCLMap ( ["u","du","wet","v","dv"],["un","vn"],["(j,1,500.0,1)","(k,1,500.0,1)"],[]) {
! OpenCLMap ( ["j","u","du","wet","v","dv"],["un","vn"],["(k,1,500.0,1)"],[]) {
    un(j,k) = 0.0
    uu = u(j,k)
    duu = du(j,k)
    if (wet(j,k)==1) then
        if ((wet(j,k+1)==1) .or. (duu>0.0)) then
                un(j,k) = uu+duu
        end if
    else
        if ((wet(j,k+1)==1) .and. (duu<0.0)) then
                un(j,k) = uu+duu
        end if
    end if
    vv = v(j,k)
    dvv = dv(j,k)
    vn(j,k) = 0.0
    if (wet(j,k)==1) then
        if ((wet(j+1,k)==1) .or. (dvv>0.0)) then
                vn(j,k) = vv+dvv
        end if
    else
        if ((wet(j+1,k)==1) .and. (dvv<0.0)) then
                vn(j,k) = vv+dvv
        end if
    end if
    }
    }
! OpenCLMap ( ["h","eta","dt","dx","dy"],["etan"],["(j,1,500.0,1)","(k,1,500.0,1)"],[]) {
! OpenCLMap ( ["j","h","eta","dt","dx","dy"],["etan"],["(k,1,500.0,1)"],[]) {
    hep = 0.5*(un(j,k)+abs(un(j,k)))*h(j,k)
    hen = 0.5*(un(j,k)-abs(un(j,k)))*h(j,k+1)
    hue = hep+hen
    hwp = 0.5*(un(j,k-1)+abs(un(j,k-1)))*h(j,k-1)
    hwn = 0.5*(un(j,k-1)-abs(un(j,k-1)))*h(j,k)
    huw = hwp+hwn
    hnp = 0.5*(vn(j,k)+abs(vn(j,k)))*h(j,k)
    hnn = 0.5*(vn(j,k)-abs(vn(j,k)))*h(j+1,k)
    hvn = hnp+hnn
    hsp = 0.5*(vn(j-1,k)+abs(vn(j-1,k)))*h(j-1,k)
    hsn = 0.5*(vn(j-1,k)-abs(vn(j-1,k)))*h(j,k)
    hvs = hsp+hsn
    etan(j,k) = eta(j,k)-dt*(hue-huw)/dx-dt*(hvn-hvs)/dy
    }
    }
end subroutine dyn

--------------------------------------------------------------------------------