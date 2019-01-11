! We have a 2-point stencil for each cov:
! cov1(i,j,k),cov1(i+1,j,k) => cov1_i, cov1_ip1
! cov2(i,j,k),cov2(i,j+1,k) cov2_j, cov2_jp1
! cov3(i,j,k),cov3(i,j,k+1) cov3_k, cov3_kp1
! cov4(i,j,k),cov4(i+1,j,k) cov4_i, cov4_ip1
! cov5(i,j,k),cov5(i,j+1,k) cov5_j, cov5_jp1
! cov6(i,j,k),cov6(i,j,k+1) cov6_k, cov6_kp1
! cov7(i,j,k),cov7(i+1,j,k) cov7_i, cov7_ip1
! cov8(i,j,k),cov8(i,j+1,k) cov8_j, cov8_jp1
! cov9(i,j,k),cov9(i,j,k+1) cov9_k, cov9_kp1
module module_velFG
!_VELFG
    use module_vel2 ! add_module_decls() line 156
    implicit none
 contains
!_VELFG
! subroutine velfg(dx1,cov1,cov2,cov3,dfu1,diu1,diu2,dy1,diu3,dzn,vn,f,cov4,cov5,cov6, &
! dfv1,diu4,diu5,diu6,g,cov7,cov8,cov9,dfw1,diu7,diu8,diu9,dzs,h,nou1,u,nou5,v,nou9,w,nou2, &
! nou3,nou4,nou6,nou7,nou8,uspd,vspd)
        subroutine velfg(dx1,dy1,dzn,f,g,h,u,v,w, &
        dfu1,dfv1,dfw1,vn,dzs, &
        diu1,diu2,diu3,diu4,diu5,diu6,diu7,diu8,diu9, &
        cov1,cov2,cov3,cov4,cov5,cov6,cov7,cov8,cov9, &
        nou1,nou2,nou3,nou4,nou5,nou6,nou7,nou8,nou9, &
        uspd,vspd) !WV: calls vel2 which uses halos
    use params_common_sn
    implicit none
!_VELFG
        real(kind=4), dimension(-1:ip+2,0:jp+2,0:kp+2) , intent(Out) :: cov1
        real(kind=4), dimension(0:ip+2,0:jp+2,0:kp+2) , intent(Out) :: cov2
        real(kind=4), dimension(0:ip+2,0:jp+2,0:kp+2) , intent(Out) :: cov3
        real(kind=4), dimension(0:ip+2,0:jp+2,0:kp+2) , intent(Out) :: cov4
        real(kind=4), dimension(-1:ip+2,0:jp+2,0:kp+2) , intent(Out) :: cov5
        real(kind=4), dimension(0:ip+2,0:jp+2,0:kp+2) , intent(Out) :: cov6
        real(kind=4), dimension(0:ip+2,0:jp+2,0:kp+2) , intent(Out) :: cov7
        real(kind=4), dimension(0:ip+2,0:jp+2,0:kp+2) , intent(Out) :: cov8
        real(kind=4), dimension(0:ip+2,0:jp+2,0:kp+2) , intent(Out) :: cov9
        real(kind=4), dimension(0:ip,jp,kp) , intent(Out) :: dfu1
        real(kind=4), dimension(ip,0:jp,kp) , intent(Out) :: dfv1
        real(kind=4), dimension(ip,jp,kp) , intent(Out) :: dfw1
        real(kind=4), intent(In) :: vn
!_VELFG
        real(kind=4), dimension(-1:ip+2,0:jp+2,0:kp+2) , intent(Out) :: diu1
        real(kind=4), dimension(0:ip+2,0:jp+2,0:kp+2) , intent(Out) :: diu2
        real(kind=4), dimension(0:ip+2,0:jp+2,0:kp+2) , intent(Out) :: diu3
        real(kind=4), dimension(0:ip+2,0:jp+2,0:kp+2) , intent(Out) :: diu4
        real(kind=4), dimension(-1:ip+2,0:jp+2,0:kp+2) , intent(Out) :: diu5
        real(kind=4), dimension(0:ip+2,0:jp+2,0:kp+2) , intent(Out) :: diu6
        real(kind=4), dimension(0:ip+2,0:jp+2,0:kp+2) , intent(Out) :: diu7
        real(kind=4), dimension(0:ip+2,0:jp+2,0:kp+2) , intent(Out) :: diu8
        real(kind=4), dimension(0:ip+2,0:jp+2,0:kp+2) , intent(Out) :: diu9
        real(kind=4), dimension(-1:ip+1) , intent(In) :: dx1
        real(kind=4), dimension(0:jp+1) , intent(In) :: dy1
        real(kind=4), dimension(-1:kp+2) , intent(In) :: dzn
        real(kind=4), dimension(-1:kp+2) , intent(In) :: dzs
        real(kind=4), dimension(0:ip,0:jp,0:kp) , intent(Out) :: f
        real(kind=4), dimension(0:ip,0:jp,0:kp) , intent(Out) :: g
        real(kind=4), dimension(0:ip,0:jp,0:kp) , intent(Out) :: h
!_VELFG
        real(kind=4), dimension(-1:ip+2,0:jp+2,0:kp+2) , intent(Out) :: nou1
        real(kind=4), dimension(0:ip+2,0:jp+2,0:kp+2) , intent(Out) :: nou2
        real(kind=4), dimension(0:ip+2,0:jp+2,0:kp+2) , intent(Out) :: nou3
        real(kind=4), dimension(0:ip+2,0:jp+2,0:kp+2) , intent(Out) :: nou4
        real(kind=4), dimension(-1:ip+2,0:jp+2,0:kp+2) , intent(Out) :: nou5
        real(kind=4), dimension(0:ip+2,0:jp+2,0:kp+2) , intent(Out) :: nou6
        real(kind=4), dimension(0:ip+2,0:jp+2,0:kp+2) , intent(Out) :: nou7
        real(kind=4), dimension(0:ip+2,0:jp+2,0:kp+2) , intent(Out) :: nou8
        real(kind=4), dimension(0:ip+2,0:jp+2,0:kp+2) , intent(Out) :: nou9
        real(kind=4) :: nou1_,nou2_,nou3_, nou4_,nou5_,nou6_,nou7_,nou8_,nou9_
        real(kind=4) :: diu1_,diu2_,diu3_,diu4_,diu5_,diu6_,diu7_,diu8_,diu9_
        real(kind=4) :: cov1_i,cov2_j,cov3_k, cov4_i,cov5_j,cov6_k, cov7_i,cov8_j,cov9_k
        real(kind=4) :: nou1_ip1,nou2_jp1,nou3_kp1,nou4_ip1,nou5_jp1,nou6_kp1,nou7_ip1,nou8_jp1,nou9_kp1
        real(kind=4) :: diu1_ip1,diu2_jp1,diu3_kp1,diu4_ip1,diu5_jp1,diu6_kp1,diu7_ip1,diu8_jp1,diu9_kp1
        real(kind=4) :: cov1_ip1,cov2_jp1,cov3_kp1,cov4_ip1,cov5_jp1,cov6_kp1,cov7_ip1,cov8_jp1,cov9_kp1
        real(kind=4), dimension(0:ip+1,-1:jp+1,0:kp+1) , intent(In) :: u
        real(kind=4), dimension(0:ip+1,-1:jp+1,0:kp+1) , intent(In) :: v
        real(kind=4), dimension(0:ip+1,-1:jp+1,-1:kp+1) , intent(In) :: w
!wall function
        real(kind=4), dimension(0:ip+1,0:jp+1) , intent(out) :: uspd
        real(kind=4), dimension(0:ip+1,0:jp+1) , intent(out) :: vspd
        integer :: i,j,k
        real(kind=4) :: covc,covx1,covy1,covz1
!
!
      call vel2( &
            nou1,nou5,nou9,nou2,nou3,nou4,nou6,nou7,nou8,&
            diu1,diu2,diu3,diu4,diu5,diu6,diu7,diu8,diu9,&
            cov1,cov2,cov3,cov4,cov5,cov6,cov7,cov8,cov9,&
            u,v,w,dx1,dy1,dzn,dzs,uspd,vspd)
!wall function
      do j=1,jp
        do i=1,ip
         uspd(i,j)=(u(i,j,1)**2+((0.5*(v(i,j-1,1)+v(i,j,1))*dx1(i+1)&
     +0.5*(v(i+1,j-1,1)+v(i+1,j,1))*dx1(i))/(dx1(i)+dx1(i+1)))**2)**0.5
        end do
        end do
        do j=1,jp
        do i=1,ip
         vspd(i,j)=(v(i,j,1)**2+((0.5*(u(i-1,j,1)+u(i,j,1))*dy1(j+1)&
     +0.5*(u(i-1,j+1,1)+u(i,j+1,1))*dy1(j))/(dy1(j)+dy1(j+1)))**2)**0.5
        end do
        end do
! WV: to get a point somewhere near the middle of the domain
        write(6,*) 'CHK_uspd_vspd=',uspd(ip/2,jp/2),vspd(ip/2,jp/2)
! --u velocity
      do k = 1,kp
      do j = 1,jp
      do i = 1,ip
        covx1 = (dx1(i+1)*cov1(i,j,k)+dx1(i)*cov1(i+1,j,k)) /(dx1(i)+dx1(i+1))
        covy1 = (cov2(i,j,k)+cov2(i,j+1,k))/2.
        covz1 = (cov3(i,j,k)+cov3(i,j,k+1))/2.
        covc = covx1+covy1+covz1
!-- molecular viscous term is neglected
! dfu1(i,j,k) = 2.*(-diu1(i,j,k)+diu1(i+1,j,k))/(dx1(i)+dx1(i+1)) + (-diu2(i,j,k)+diu2(i, &
! j+1,k))/dy1(j) + (-diu3(i,j,k)+diu3(i,j,k+1))/dzn(k)
! df = vn*dfu1(i,j,k)
! f(i,j,k) = (-covc+df)
!--
        f(i,j,k) = (-covc)
      end do
      end do
      end do
! =======================================
! --v velocity
      do k = 1,kp
      do j = 1,jp
      do i = 1,ip
!4
        covx1 = (cov4(i,j,k)+cov4(i+1,j,k))/2.
        covy1 = (dy1(j+1)*cov5(i,j,k)+dy1(j)*cov5(i,j+1,k)) /(dy1(j)+dy1(j+1))
        covz1 = (cov6(i,j,k)+cov6(i,j,k+1))/2.
        covc = covx1+covy1+covz1
!-- molecular viscous term is neglected
! dfv1(i,j,k) = (-diu4(i,j,k)+diu4(i+1,j,k))/dx1(i) +2.*(-diu5(i,j,k)+diu5(i,j+1, &
! k))/(dy1(j)+dy1(j+1)) +(-diu6(i,j,k)+diu6(i,j,k+1))/dzn(k)
! df = vn*dfv1(i,j,k)
! g(i,j,k) = (-covc+df)
!--
        g(i,j,k) = (-covc)
      end do
      end do
      end do
!
! =======================================
! --w velocity
      do k = 1,kp-1
      do j = 1,jp
      do i = 1,ip
      !if (k<kp) then
!7
       covx1 = (cov7(i,j,k)+cov7(i+1,j,k))/2.
       covy1 = (cov8(i,j,k)+cov8(i,j+1,k))/2.
       covz1 = (dzn(k+1)*cov9(i,j,k)+dzn(k)*cov9(i,j,k+1)) /(dzn(k)+dzn(k+1))
       covc = covx1+covy1+covz1
!-- molecular viscous term is neglected
! dfw1(i,j,k) = (-diu7(i,j,k)+diu7(i+1,j,k))/dx1(i) +(-diu8(i,j,k)+diu8(i,j+1, &
! k))/dy1(j) +(-diu9(i,j,k)+diu9(i,j,k+1))/dzs(k)
! df = vn*dfw1(i,j,k)
! h(i,j,k) = (-covc+df)
!--
        h(i,j,k) = (-covc)
      end do
      end do
      end do
! WV: This seems not necessary, perhaps because it is called in press.
!
! =======================================
      return
      end subroutine velFG
end module module_velFG