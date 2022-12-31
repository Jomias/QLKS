/*Câu 1: Tạo view đưa ra danh sách các phòng trong khách sạn có tình trạng VC hoặc VCC điểm hiện tại*/
CREATE OR ALTER VIEW BTL_V_1
AS
SELECT * FROM PHONG
WHERE TinhTrang IN ('VC', 'VCC')
ALTER TABLE PHIEUTHUE
ADD KMPhong float
GO
SELECT * FROM BTL_V_1


/*Câu 2: Tạo view đưa ra danh sách các dịch vụ không được sử dụng trong khách sạn trong năm 2022*/
CREATE OR ALTER VIEW BTL_V_2
AS
SELECT MaDV, TenDV, DonViTinh, MaNhomDV
FROM DICHVU
WHERE MaDV NOT IN (SELECT MaDV FROM CHITIETDICHVU
				  WHERE YEAR(ThoigianSDDV) = 2022)
	  AND MaDV NOT IN (SELECT MaDV FROM DONGHDTT
					  WHERE YEAR(Thoigiansudung) = 2022)
GO
SELECT * FROM BTL_V_2


/*Câu 3: Tạo view đưa ra danh sách những phòng có thể cho khách thuê được ở thời điểm hiện tại*/
CREATE OR ALTER VIEW BTL_V_3
AS
SELECT Phong.*
FROM PHONG
WHERE Maphong NOT IN (SELECT Maphong
					  FROM PHIEUDAT JOIN PHIEUTHUE
					  ON PHIEUDAT.MaBooking = PhieuThue.MaBooking
					  WHERE NgayDenDuKien <= GETDATE() AND GETDATE() <= NgayDiDuKien)
	  AND TinhTrang = 'VCC'
GO
SELECT * FROM BTL_V_3


/*Câu 4: Tạo view đưa ra danh sách khách hàng và số phòng họ đã đặt từ khách sạn*/
CREATE OR ALTER VIEW BTL_V_4
AS
SELECT KHACHHANG.MaKH, TenKH, DiaChi, DienThoai, CCCD, Tuoi,
iif(GioiTinh = 1, N'Nam', N'Nữ') AS GioiTinh, SUM(SLPhong) SoPhongThue
FROM KHACHHANG JOIN PHIEUDAT 
ON KHACHHANG.MaKH = PHIEUDAT.MaKH JOIN CHITIETPHONGDAT
ON PHIEUDAT.MaBooking = CHITIETPHONGDAT.MaBooking
GROUP BY KHACHHANG.MaKH, TenKH, DiaChi, DienThoai, CCCD, Tuoi, GioiTinh
GO
SELECT * FROM BTL_V_4


/*Câu 5 Tạo view đưa ra top 2 khách hàng có số lần đặt phòng nhiều nhất*/
CREATE OR ALTER VIEW BTL_V_5
AS
SELECT TOP 2 WITH TIES KHACHHANG.MaKH, TenKH, DiaChi, DienThoai, CCCD, Tuoi,
iif(GioiTinh = 1, N'Nam', N'Nữ') AS GioiTinh, COUNT(MaBooking) SoLanDatPhong
FROM KHACHHANG JOIN PHIEUDAT 
ON KHACHHANG.MaKH = PHIEUDAT.MaKH
GROUP BY KHACHHANG.MaKH, TenKH, DiaChi, DienThoai, CCCD, Tuoi, GioiTinh
ORDER BY 8 DESC
GO
SELECT * FROM BTL_V_5


/*Câu 6 Tạo view đưa ra thông tin tất cả các nhân viên của khách sạn, bao gồm cả chức vụ 
và bộ phận làm việc của nhân viên đó */
CREATE OR ALTER VIEW BTL_V_6
AS 
SELECT NHANVIEN.MaNV, TenNV, SoCMND, SDT, iif(GioiTinh = 1, N'Nam', N'Nữ') AS GioiTinh,
TenCV AS ChucVu, TenBP AS BPLamViec
FROM NHANVIEN JOIN CHUCVU 
ON NHANVIEN.MaCV = CHUCVU.MaCV JOIN BOPHANLAMVIEC
ON NHANVIEN.MaBP = BOPHANLAMVIEC.MaBP
GO
SELECT * FROM BTL_V_6


/*Câu 7 Tạo view đưa ra top 3 dịch vụ có số lần sử dụng nhiều nhất trong các hóa đơn của khách sạn*/
CREATE OR ALTER VIEW BTL_V_7
AS
SELECT TOP 3 WITH TIES A.MaDV, A.TenDV, ISNULL(SL1, 0) AS SLHDDV,  
ISNULL(SL2, 0) AS SLHDTT, ISNULL(SL1, 0) + ISNULL(SL2, 0) AS TongSL
FROM DICHVU A FULL JOIN (SELECT DICHVU.MaDV, COUNT(SLDV) AS SL1
					FROM DICHVU JOIN CHITIETDICHVU
					ON DICHVU.MaDV = CHITIETDICHVU.MaDV
					GROUP BY DICHVU.MaDV) AS B1
	ON A.MaDV = B1.MaDV FULL JOIN (SELECT DICHVU.MaDV, COUNT(SLDichVu) AS SL2
							 FROM DICHVU JOIN DONGHDTT
							 ON DICHVU.MaDV = DONGHDTT.MaDV
							 GROUP BY DICHVU.MaDV) B2
	ON A.MaDV = B2.MaDV
ORDER BY 5 DESC
GO
SELECT * FROM BTL_V_7


/*Câu 8 Tạo view đưa ra những hóa đơn thanh toán có tổng tiền cao nhất và cao nhì trong năm 2022*/
CREATE OR ALTER VIEW BTL_V_8
AS
SELECT B2.MaHDTT, ISNULL(TTDV, 0) + TTPhong AS TienHoaDon
FROM (SELECT HOADONTT.MaHDTT, SUM(SLDichVu * DonGiaDV * (1 - ISNULL(KMDV, 0))) AS TTDV
	 FROM DONGHDTT JOIN HOADONTT
	 ON HOADONTT.MaHDTT = DONGHDTT.MaHDTT
	 WHERE YEAR(NgayTT) = 2022
	 GROUP BY HOADONTT.MaHDTT) B1 RIGHT JOIN 
	 (SELECT MaHDTT, 	
	 SUM(PhieuThue.DonGiaPhong * DATEDIFF(DAY, ThoiGianCheckIn, ThoiGianCheckOut) * (1 - ISNULL(KMPhong, 0))) TTPhong
	 FROM HOADONTT JOIN PHIEUTHUE
	 ON HOADONTT.MaBooking = PHIEUTHUE.MaBooking
	 WHERE YEAR(NgayTT) = 2022
	 GROUP BY MAHDTT) B2
ON B1.MaHDTT = B2.MaHDTT
WHERE ISNULL(TTDV, 0) + TTPhong IN
(SELECT DISTINCT TOP 2 ISNULL(TTDV, 0) + TTPhong
FROM (SELECT HOADONTT.MaHDTT, SUM(SLDichVu * DonGiaDV * (1 - ISNULL(KMDV, 0))) AS TTDV
	FROM DONGHDTT JOIN HOADONTT
	ON HOADONTT.MaHDTT = DONGHDTT.MaHDTT
	WHERE YEAR(NgayTT) = 2022
	GROUP BY HOADONTT.MaHDTT) B1 RIGHT JOIN 
	(SELECT MaHDTT, 	
	SUM(PhieuThue.DonGiaPhong * DATEDIFF(DAY, ThoiGianCheckIn, ThoiGianCheckOut)
	* (1 - ISNULL(KMPhong, 0))) TTPhong
	FROM HOADONTT JOIN PHIEUTHUE
	ON HOADONTT.MaBooking = PHIEUTHUE.MaBooking
	WHERE YEAR(NgayTT) = 2022
	GROUP BY MAHDTT) B2
	ON B1.MaHDTT = B2.MaHDTT
	ORDER BY 1 DESC)
GO
SELECT * FROM BTL_V_8


/*Hàm*/
/*Câu 1: Tạo hàm có đầu vào là ngày, đầu ra là danh sách khách hàng sẽ đến khách sạn vào ngày đó*/
CREATE OR ALTER FUNCTION BTL_F_C1(@Ngay date)
RETURNS TABLE AS
RETURN
(
	SELECT KHACHHANG.MaKH, TenKH, DiaChi, CCCD, Tuoi, iif(GioiTinh = 1, N'Nam', N'Nữ') GioiTinh
	FROM KHACHHANG JOIN PHIEUDAT
	ON KHACHHANG.MaKH = PHIEUDAT.MaKH
	WHERE @Ngay = NgayDenDukien
)
GO
SELECT * FROM BTL_F_C1('2022-3-10')


/*Câu 2: Tạo hàm có đầu vào là mã dịch vụ, đầu ra là các mã hóa đơn dịch vụ hoặc mã hóa đơn thanh toán
có bao gồm dịch vụ này*/
CREATE OR ALTER FUNCTION BTL_F_C2(@MaDV nvarchar(10))
RETURNS TABLE AS
RETURN
(
	SELECT DISTINCT MaHDDV AS MaHD, 'HDDV' AS LoaiHD
	FROM CHITIETDICHVU 
	WHERE MaDV = @MaDV
	UNION
	SELECT DISTINCT MaHDTT, 'HDTT'
	FROM DONGHDTT
	WHERE MaDV = @MaDV	
)
GO
SELECT * FROM BTL_F_C2(N'DV002')


/*Câu 3: Tạo hàm có đầu vào là tháng, đầu ra là bảng thống kê 
tiền thu được từ các loại phòng của khách sạn trong tháng đó */
CREATE OR ALTER FUNCTION BTL_F_C3(@Thang int, @Nam int)
RETURNS TABLE AS
RETURN
(
	SELECT B1.MaLP, KieuPhong, ISNULL(TongTien, 0) N'Tổng tiền'
	FROM LoaiPhong B1 LEFT JOIN 
	(SELECT LoaiPhong.MaLP, 
	SUM(PhieuThue.DonGiaPhong * DATEDIFF(DAY, ThoiGianCheckIn, ThoiGianCheckOut) * (1 - ISNULL(KMPhong, 0))) TongTien
	FROM PHONG JOIN PHIEUTHUE
	ON PHONG.MaPhong = PHIEUTHUE.MaPhong JOIN HOADONTT
	ON PHIEUTHUE.MaBooking = HOADONTT.MaBooking JOIN LOAIPHONG
	ON Phong.MaLP = LOAIPHONG.MaLP
	WHERE YEAR(NgayTT) = @Nam AND MONTH(NgayTT) = @Thang
	GROUP BY LoaiPhong.MaLP) B2
	ON B1.MaLP = B2.MaLP
)
GO
SELECT * FROM BTL_F_C3(2, 2022)


/*Câu 4: Tạo hàm có đầu vào là Năm, đầu ra là các hóa đơn dịch vụ do nhân viên nam lập 
và tổng tiền của các hóa đơn dịch vụ đó trong năm đã cho*/
CREATE OR ALTER FUNCTION BTL_F_C4(@Nam int)
RETURNS TABLE AS
RETURN
(
	SELECT HDDV.MaNV, TenNV, HDDV.MaHDDV, ThoiGianLap, MaKH,
	SUM(SLDV * DongiaDV * (1 - ISNULL(KMDV, 0))) 'TongTien'
	FROM HDDV JOIN CHITIETDICHVU
	ON HDDV.MaHDDV = CHITIETDICHVU.MaHDDV JOIN NHANVIEN
	ON NHANVIEN.MaNV = HDDV.MaNV
	WHERE YEAR(ThoiGianLap) = @Nam AND GioiTinh = 1
	GROUP BY HDDV.MaNV, TenNV, HDDV.MaHDDV, ThoiGianLap, MaKH
)
GO
SELECT * FROM BTL_F_C4(2022)


/*Câu 5: Tạo hàm có đầu vào là diện tích, đầu ra là Top 2 phòng của khách sạn có 
số lượt thuê cao nhất có diện tích lớn hơn diện tích đã cho này*/
CREATE OR ALTER FUNCTION BTL_F_C5(@DienTich float)
RETURNS TABLE AS 
RETURN
(
	SELECT TOP 3 WITH TIES PHONG.Maphong, COUNT(MaPT) SoLuotThue
	FROM PHONG LEFT JOIN PHIEUTHUE
	ON PHONG.MaPhong = PHIEUTHUE.MaPhong JOIN LOAIPHONG
	ON PHONG.MaLP = LOAIPHONG.MaLP
	WHERE DienTich > @DienTich
	GROUP BY PHONG.Maphong
	ORDER BY 2 DESC
)
GO
SELECT * FROM BTL_F_C5(30)


/*Câu 6: Tạo hàm có đầu vào là mã khách hàng, đầu ra là danh sách các hóa đơn, thời gian xuất hóa đơn
và tổng trị giá các hóa đơn mà khách hàng đó đã thanh toán*/
CREATE OR ALTER FUNCTION BTL_F_C6(@MaKH nvarchar(10))
RETURNS TABLE AS
RETURN
(
	SELECT HDDV.MaHDDV AS MaHD, ThoiGianLap AS ThoiGianXuat, 'HDDV' AS LoaiHD,
	SUM(SLDV * DonGiaDV * (1 - ISNULL(KMDV, 0))) AS TongTien
	FROM CHITIETDICHVU JOIN HDDV
	ON CHITIETDICHVU.MaHDDV = HDDV.MaHDDV 
	WHERE MaKH = @MaKH
	GROUP BY HDDV.MaHDDV, ThoiGianLap
	UNION
	SELECT B2.MaHDTT, B2.NgayTT, 'HDTT', ISNULL(TTDV, 0) + TTPhong
	FROM (SELECT HOADONTT.MaHDTT, NgayTT, SUM(SLDichVu * DonGiaDV * (1 - ISNULL(KMDV, 0))) AS TTDV
		FROM DONGHDTT JOIN HOADONTT
		ON HOADONTT.MaHDTT = DONGHDTT.MaHDTT JOIN PHIEUDAT
		ON HOADONTT.MaBooking = PHIEUDAT.MaBooking
		WHERE NgayTT IS NOT NULL AND MaKH = @MaKH
		GROUP BY HOADONTT.MaHDTT, NgayTT) B1 RIGHT JOIN 
		(SELECT MaHDTT, NgayTT, 	
		SUM(PhieuThue.DonGiaPhong * DATEDIFF(DAY, ThoiGianCheckIn, ThoiGianCheckOut)
		* (1 - ISNULL(KMPhong, 0))) TTPhong
		FROM HOADONTT JOIN PHIEUDAT
		ON HOADONTT.MaBooking = PhieuDat.MaBooking JOIN PHIEUTHUE
		ON HOADONTT.MaBooking = PHIEUTHUE.MaBooking
		WHERE NgayTT IS NOT NULL AND MaKH = @MaKH
		GROUP BY MAHDTT, NgayTT) B2
	ON B1.MaHDTT = B2.MaHDTT
)
GO
SELECT * FROM BTL_F_C6(N'KH0002')


/*Thủ tục*/

/*Câu 1: Tạo thủ tục dịch vụ vào cơ sở dữ liệu*/
CREATE PROCEDURE BTL_P_1 @MaDV nvarchar(10), @TenDV nvarchar(50), @DonViTinh nvarchar(10), @MaNhomDV nvarchar(10)
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION
			
			INSERT INTO DICHVU(MaDV, TenDV, DonViTinh, MaNhomDV) VALUES (@MaDV, @TenDV, @DonViTinh, @MaNhomDV)
			SELECT * FROM DICHVU
		COMMIT TRANSACTION 
	END TRY
	BEGIN CATCH 
			SELECT N'Đã xảy ra lỗi' AS KetQua
			ROLLBACK TRANSACTION
	END CATCH
END	
EXEC BTL_P_1 'DV2', 'DV4', N'lần', 'NDV0105'


/*2. Tạo thủ tục đầu vào mã khách hàng đầu ra là số lượng phòng khách đặt*/
create or alter procedure BTL_P_2 @MaKH nvarchar(10), @Sophongdadat int out
as
	begin try
			select @Sophongdadat = count(B.Maphong)
			from PHIEUDAT A inner join PHIEUTHUE B on A.MaBooking = B.Mabooking
			Where A.MaKH = @MaKH
	end try
	begin catch
		select ERROR_NUMBER() as ErrorNumber, ERROR_MESSAGE() as ErrorMessage
	end catch
go

Declare	@SoPhong int
Exec	BTL_P_2 'KH0002', @SoPhong out
Select	@SoPhong as SoPhongDaDat


/*3. Tạo thủ tục cập nhật tình trạng phòng*/
create or alter procedure BTL_P_3_ @Maphong nvarchar(10), @Tinhtrang nvarchar(50)
as
	begin
		update PHONG
		set
			Tinhtrang = @Tinhtrang
		where Maphong = @Maphong
	end

exec BTL_P_3_ N'P401', N'Dirty'
select * from PHONG

-- 4. Tạo thủ tục là đầu vào là tháng, năm đầu ra là tổng tiền hóa đơn phòng của tháng và năm đó
create or alter procedure BTL_P_4 @Thang int, @Nam int, @Tongtien int out
as
begin
	select @Tongtien = SUM(B.Dongiaphong * DATEDIFF(DAY, B.Thoigiancheckin, B.Thoigiancheckout) - B.Dongiaphong * B.KMPhong - A.Tiendatcoc) 
	from PHIEUDAT A inner join PHIEUTHUE B on A.MaBooking = B.MaBooking inner join HOADONTT C on A.MaBooking = C.MaBooking
	where YEAR(C.NgayLapHD) = @Nam and MONTH(C.NgayLapHD) = @Thang
end

declare @Tong int
exec BTL_P_4 2, 2022, @Tong out
select @Tong as TongTienHD

/*Câu 5: Tạo thủ tục xóa thông tin những khách hàng không đặt phòng cũng không sử dụng dịch vụ nào khác*/
CREATE OR ALTER PROCEDURE BTL_P_5
AS
BEGIN
	DELETE KHACHHANG
	WHERE MaKH NOT IN (SELECT MaKH FROM HDDV)
		  AND MaKH NOT IN (SELECT MaKH FROM PHIEUDAT)
END
EXEC BTL_P_5
SELECT * FROM KHACHHANG

/*Câu 6: Tạo thủ tục có đầu vào là năm, đầu ra là doanh thu của khách sạn trong năm đó*/
CREATE OR ALTER PROCEDURE BTL_P_6 @Nam int, @DoanhThu Money OUTPUT
AS
BEGIN
	SELECT @DoanhThu = 0
	SELECT @DoanhThu = @DoanhThu + ISNULL(SUM(SLDV * DonGiaDV * (1 - ISNULL(KMDV, 0))), 0)
	FROM CHITIETDICHVU JOIN HDDV
	ON CHITIETDICHVU.MaHDDV = HDDV.MaHDDV
	WHERE YEAR(ThoigianSDDV) = @Nam
	SELECT @DoanhThu = @DoanhThu + ISNULL(SUM(SLDichVu * DonGiaDV * (1 - ISNULL(KMDV, 0))), 0)
	FROM HOADONTT JOIN DONGHDTT
	ON HOADONTT.MaHDTT = DONGHDTT.MaHDTT
	WHERE YEAR(NgayTT) = @Nam
	SELECT @DoanhThu = @DoanhThu + ISNULL(SUM(PhieuThue.DonGiaPhong * DATEDIFF(DAY, ThoiGianCheckIn, ThoiGianCheckOut)
	* (1 - ISNULL(KMPhong, 0))), 0)
	FROM HOADONTT JOIN PHIEUTHUE
	ON PHIEUTHUE.MaBooking = HOADONTT.MaBooking
	WHERE YEAR(NgayTT) = @Nam
END
GO
DECLARE @DoanhThu Money
EXEC BTL_P_6 '2022', @DoanhThu OUTPUT
SELECT @DoanhThu AS DoanhThu


/*Trigger*/
/*Câu 1 Tạo trigger tự động cập nhật đơn giá phòng trên phiếu thuê mỗi khi thêm 1 bản ghi*/
CREATE OR ALTER TRIGGER BTL_T_C1 ON PHIEUTHUE
FOR INSERT AS
BEGIN
	DECLARE @MaPT nvarchar(10), @DonGiaPhong Money
	SELECT @MaPT = inserted.MaPT, @DonGiaPhong = LoaiPhong.DonGiaPhong
	FROM inserted JOIN PHONG 
	ON inserted.MaPhong = PHONG.MaPhong JOIN LOAIPHONG
	ON PHONG.MaLP = LOAIPHONG.MaLP
 	UPDATE PHIEUTHUE 
	SET DonGiaPhong = @DonGiaPhong
	WHERE MaPT = @MaPT
END

/*Câu 2: Thêm trường số lượng hóa đơn dịch vụ lập (SoluongHDDV) vào bảng nhân viên, tạo trigger tự động cập nhật khi thêm bản HDDV */
alter table NHANVIEN
add SoluongHDDV int

update NHANVIEN set SoluongHDDV = (select SoluongHDDV = isnull(COUNT(HDDV.MaHDDV), 0)
								   from HDDV
								   where NHANVIEN.MaNV = HDDV.MaNV)

create or alter trigger BTL_T_C2 on HDDV
for insert
as begin
	update NHANVIEN set SoluongHDDV = (select SoluongHDDV = COUNT(HDDV.MaHDDV)
									   from NHANVIEN, HDDV, inserted
									   where NHANVIEN.MaNV = HDDV.MaNV and NHANVIEN.MaNV = inserted.MaNV)
	where exists(select *
				 from inserted
				 where NHANVIEN.MaNV = inserted.MaNV)
end

/*Câu 3: Tạo cột số lần thuê trong bảng phòng. Tự động update cột này khi thêm sửa xóa Phiếu thuê*/
ALTER TABLE PHONG
ADD SoLanThue INT
CREATE OR ALTER TRIGGER BTL_T_C3 ON PHIEUTHUE
FOR INSERT, DELETE, UPDATE AS
BEGIN
	DECLARE @PIn nvarchar(10), @PDe nvarchar(10)
	SELECT @PIn = inserted.MaPhong FROM inserted
	SELECT @PDe = deleted.MaPhong FROM deleted
	UPDATE PHONG SET SoLanThue = ISNULL(SoLanThue, 0) + 1 WHERE MaPhong = @PIn
	UPDATE PHONG SET SoLanThue = ISNULL(SoLanThue, 0) - 1 WHERE MaPhong = @PDe
END

/*Câu 4: Tạo trigger xóa toàn bộ thông tin liên quan khi xóa thông tin 1 khách */
CREATE OR ALTER BTL_T_C4 ON KhachHang
INSTEAD OF DELETE
AS
BEGIN
	DECLARE @MaKH nvarchar(10)
	SELECT @MaKH = MaKH FROM deleted
	DELETE CHITIETDICHVU
	WHERE MaHDDV IN (SELECT HDDV.MaHDDV FROM CHITIETDICHVU JOIN HDDV
				ON HDDV.MaHDDV = CHITIETDICHVU.MaHDDV JOIN KHACHHANG
				ON KHACHHANG.MaKH = HDDV.MaKH WHERE HDDV.MaKH = @MaKH)
	DELETE HDDV WHERE MaKH = @MaKH
	DELETE PHIEUTHUE
	WHERE MaBooking IN (SELECT MaBooking FROM PHIEUDAT
						WHERE MaKH = @MaKH)
	DELETE CHITIETPHONGDAT
	WHERE MaBooking IN (SELECT MaBooking FROM PHIEUDAT
						WHERE MaKH = @MaKH)
	DELETE DONGHDTT
	WHERE MaHDTT IN (SELECT MaHDTT FROM HOADONTT JOIN PHIEUDAT
					ON HOADONTT.MaBooking = PHIEUDAT.MaBooking
					WHERE MaKH = @MaKH)
	DELETE HOADONTT 
	WHERE MaHDTT IN (SELECT MaHDTT FROM HOADONTT JOIN PHIEUDAT
					ON HOADONTT.MaBooking = PHIEUDAT.MaBooking
					WHERE MaKH = @MaKH)
	DELETE PHIEUDAT WHERE MaKH = @MaKH
	DELETE KHACHHANG WHERE MaKH = @MaKH
END

/*Câu 5: Tạo trigger tự động cập nhật tình trạng phòng là Occupied khi khách Check In, Dirty khi khách Check OUT */
CREATE OR ALTER TRIGGER BTL_T_C5 ON PHIEUTHUE
FOR UPDATE AS
BEGIN
	DECLARE @T1In DateTime, @T2In DateTime, @T1De DateTime, @T2De DateTime, @MaPhong nvarchar(10)
	SELECT @MaPhong = inserted.MaPhong, @T1In = inserted.ThoiGianCheckIn, @T2In = inserted.ThoiGianCheckOUT FROM inserted
	SELECT @T1De = deleted.ThoiGianCheckIn, @T2De = deleted.ThoiGianCheckOUT FROM deleted
	UPDATE PHONG
	SET TinhTrang = 'Occupied'
	WHERE @T1De IS NULL AND @T1In IS NOT NULL AND MaPhong = @MaPhong 
	UPDATE PHONG
	SET TinhTrang = 'Dirty'
	WHERE @T2De IS NULL AND @T2In IS NOT NULL AND MaPhong = @MaPhong
END


/*Câu 6 Tạo trigger để kiểm tra mỗi khi thêm hoặc sửa phiếu thuê, tổng số lượng phòng mỗi loại của Mã Booking tương ứng không vượt quá số lượng phòng mà khách đã đặt*/
CREATE OR ALTER TRIGGER BTL_T_C6 ON PHIEUTHUE
FOR INSERT, UPDATE AS
BEGIN
	DECLARE @MaLP nvarchar(10), @MaBooking nvarchar(10)
	, @SLPhongDat int, @SLPhongThue int

	SELECT @MaLP = Phong.MaLP, @MaBooking = MaBooking
	FROM inserted JOIN PHONG
	ON inserted.MaPhong = PHONG.MaPhong
	SELECT @SLPhongDat = SLPhong
	FROM CHITIETPHONGDAT
	WHERE MaBooking = @MaBooking AND MaLP = @MaLP

	SELECT @SLPhongThue = COUNT(MaPT)
	FROM PHIEUTHUE JOIN PHONG
	ON PHIEUTHUE.MaPhong = PHONG.MaPhong JOIN PHIEUDAT
	ON PHIEUDAT.MaBooking = PHIEUTHUE.MaBooking
	WHERE MaLP = @MaLP AND PHIEUDAT.MaBooking = @MaBooking
	IF (@SLPhongThue > ISNULL(@SLPhongDat, 0))
		BEGIN
			PRINT N'Số lượng loại phòng này đã vượt quá số lượng khách đặt'
			ROLLBACK TRAN
		END
END


/*Kịch bản*/
-- Kịch bản 1
--1.Tạo login NguyenHaiDang, tạo user NguyenHaiDang cho NguyenHaiDang trên CSDL QLyKhachSan
Create login NguyenHaiDang with password = '123'

Create user NguyenHaiDang for login NguyenHaiDang

--2. Phân quyền select trên bảng View câu1 cho NguyenHaiDang 
Grant select on BTL_V_1 to NguyenHaiDang

--3. Xoá quyền select của NguyenHaiDang trên bảng View câu1
Revoke select on BTL_V_1 from NguyenHaiDang

-- Kịch bản 2
--1.Tạo login TranQuangDuc, tạo user TranQuangDuc cho TranQuangDuc trên CSDL QLyKhachSan
Create login TranQuangDuc with password = '123'

Create user TranQuangDuc for login TranQuangDuc

--2. Phân quyền select trên bảng PHIEUTHUE cho TranQuangDuc, TranQuangDuc được phép phân quyền
-- cho người khác 
Grant select on PHIEUTHUE to TranQuangDuc with grant option

-- 3. Từ login TranQuangDuc, phân quyền Select trên bảng PHIEUTHUE cho NguyenHaiDang
Grant Select on PHIEUTHUE to NguyenHaiDang

-- Kịch bản 3
--1.Tạo login NguyenThiTuyet, tạo user NguyenThiTuyet cho NguyenThiTuyet trên CSDL QLyKhachSan
Create login NguyenThiTuyet with password = '123'

Create user NguyenThiTuyet for login NguyenThiTuyet

--2. Phân quyền select trên bảng Hàm câu2 cho NguyenThiTuyet 
Grant select on BTL_F_C2 to NguyenThiTuyet

-- 3. Xoá login NguyenThiTuyet
Drop login NguyenThiTuyet






