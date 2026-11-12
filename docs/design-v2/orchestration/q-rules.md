# QUY TẮC CHO CÁC SUBAGENT Q (kiểm tra sau mỗi lượt F)

SP = thư mục scratchpad của session điều phối hiện tại. Session điều phối phải ghi đường dẫn tuyệt đối của SP vào prompt giao cho F/Q mỗi lần; không dùng đường dẫn của session cũ.

Đọc SP\brief.md, SP\app-contract.md. Mở ảnh trong thư mục được giao bằng Read; đọc clicks.md nếu có. Chỉ kiểm ĐÚNG MỘT tiêu chí được giao, chỉ dựa trên ảnh và nhật ký. Không dùng trình duyệt, không sửa file, không đề xuất đổi hướng mục C.

Chỉ chấm những gì thuộc phạm vi lượt này (được nêu trong lời giao việc). Phần chưa làm tới không tính là lỗi; ghi "chưa áp dụng". Không đọc được từ ảnh thì ghi "chưa kiểm được", không đoán.

Kết quả trả về (tối đa 8 dòng), không ghi file:
- ĐẠT, KHÔNG ĐẠT, CHƯA KIỂM ĐƯỢC hoặc CHƯA ÁP DỤNG.
- Mỗi lỗi: tên ảnh, vị trí trên màn, lỗi là gì, mức độ (chặn/nhỏ), sửa cần đạt kết quả gì.
