# So sánh V1 (tối giản) và V2 (Journey DNA), kèm nghiên cứu thị hiếu người dùng

Ngày 2026-11-11. Nguồn: Make V1 (`z3B1WO8e7SUNG83jvaPotn`, đọc qua Figma MCP), Make V2 bản 29, `README.md` mục 0, hai lượt nghiên cứu web (6 lượt tìm mỗi lượt, chỉ đọc đoạn trích, không có khảo sát trực tiếp so sánh hai hướng).

## 1. Hai bản khác nhau ở đâu

| Mặt | V1 tối giản | V2 Journey DNA |
|---|---|---|
| Tạo hành trình | Một form dài chung (tên, emoji, một mình/nhóm, thời lượng, chỉ số, hiển thị, múi giờ) hoặc chọn mẫu + Quick setup | 5 bước, mỗi loại có câu hỏi riêng, kết thúc bằng "vé khởi hành" |
| Trong hành trình | Một màn chi tiết dùng chung: tiến độ "Day 25/30 · 83%", ô số liệu, tab Story/Lịch, lưới ngày | Mỗi loại một bố cục: đường cân nặng (Quiet), con đường quest (Squad), cuộn phim/sổ dán (Memory), hai nửa (Couple), telemetry neon (Flexer), lịch chuỗi (Minimalist) |
| Style | 10 style, chỉ đổi màu nhấn + nền | 6 skin đổi cả chất liệu, font, HUD camera, thiệp chia sẻ; 3 biến thể màu mỗi skin; đổi được bố cục theo dữ liệu |
| Vỏ | Sạch, trung tính, icon Lucide | Neo-brutalism mềm (nền kem, viền 2px, bóng cứng), sticker, dock 5 nút có kính mờ |
| Xã hội | Nhiều: bạn bè, inbox, chat, insights, story editor, chia sẻ | Gọn: Hội (điểm danh, nhắc nhẹ, reaction), Hoạt động; không bình luận, không xếp hạng |
| Chụp | Camera chung | Camera theo skin, nhấn giữ nút chụp để đổi hành trình; vẫn ≤ 3 chạm |
| Chi phí làm | Thấp: một bộ màn | Cao: 6 bố cục × (timeline, HUD, thiệp, ngày, wrapped), QA và a11y nhân lên |

## 2. Người dùng thích bên nào (tóm tắt nghiên cứu)

Không tìm thấy nghiên cứu so sánh trực tiếp; kết luận dưới đây suy ra từ bằng chứng gần.

1. **Thứ giết app thói quen là công sức ghi chép, không phải giao diện** (Epstein et al., CHI 2016: người dùng bỏ vì phiền và chán). Câu hỏi riêng lúc tạo của V2 làm tăng công sức đầu vào.
2. **Đẹp giúp người dùng bỏ qua lỗi nhỏ, không bù được lỗi lớn** (NN/g, aesthetic-usability effect). Đẹp dễ che lỗi khi test, nên phải đo tỉ lệ hoàn thành việc, không chỉ hỏi "thích không".
3. **Biểu cảm có thể vừa được thích vừa nhanh hơn**: Google Material 3 Expressive, nhóm Gen Z chọn bản biểu cảm 87% (nghiên cứu nội bộ Google, chưa kiểm chứng độc lập), nhưng đó là *một* hệ thống biểu cảm nhất quán, không phải mỗi ngữ cảnh một hệ.
4. **Locket và BeReal thắng nhờ một cơ chế đơn giản và vòng thân thiết, không nhờ đa dạng hình ảnh.** Ở Việt Nam Locket được gọi là "intimate social" (tối đa 20 bạn), UI tối giản. BeReal tụt người dùng khi hết mới lạ.
5. **Gu Gen Z Việt nghiêng về hoài cổ, film, sticker, scrapbook**: 54% Gen Z thích phong cách cổ điển/film (VnEconomy), trào lưu máy CCD cũ, sticker như "huy hiệu cá nhân", poster tổng kết chuyến đi dạng scrapbook. Không có bằng chứng riêng cho neo-brutalism gắt; gu đọc ra là "dễ thương, hoài cổ", không "brutal".
6. **Phân phối dựa vào Zalo, TikTok, Instagram, Threads** (Q&Me 2025–2026): thiệp chia sẻ đẹp theo từng hành trình là lợi thế thật của V2.
7. **Hành trình giảm cân cần riêng tư, yên tĩnh**: body shaming là vấn đề được nhắc tới; không nên phủ sticker hay gợi ý chia sẻ.

## 3. Kết luận

**Người dùng nhiều khả năng thích V2 hơn ở phần nhìn và chia sẻ, nhưng thích V1 hơn ở phần thao tác hằng ngày.** Hướng nên chốt là lai, nghiêng V2 (độ tin cậy trung bình thấp, khoảng 60/40):

- **Giữ của V1:** chụp và đăng tối giản như Locket (≤ 3 chạm, không hỏi thêm); một mô hình dữ liệu và một kiểu tương tác chung cho mọi hành trình; tạo hành trình ngắn, chỉ 1–2 câu riêng theo loại, hiện dần.
- **Giữ của V2:** cá tính nằm ở *đầu ra*: timeline, thiệp chia sẻ, Wrapped, HUD camera. Ưu tiên các thế giới có giá trị chia sẻ: Memory (cuộn phim/scrapbook), Couple (hai nửa), Squad (điểm danh hội). Minimalist làm mặc định.
- **Chỉnh V2:** vỏ ngả về dễ thương/hoài cổ hơn là brutal gắt; Quiet (giảm cân) giữ yên, không sticker, không nhắc chia sẻ.
- **Giữ đủ 6 giao diện V2 đã làm**; giảm rủi ro bằng token chung và cổng chất lượng cho từng giao diện, đo kích hoạt và giữ chân ngày 7 / ngày 30 so với V1. Chi tiết trong [improvement-plan.md](improvement-plan.md).

## 4. Cách kiểm chứng nhanh

- Test 5–8 người 18–30 tuổi trên hai prototype Make: (a) tạo hành trình và chụp lần đầu (đo thời gian, số lần bấm, chỗ bối rối), (b) xem lại sau "21 ngày" và chia sẻ (đo mức muốn chia sẻ), (c) hỏi chọn bản nào và vì sao.
- Một khảo sát ngắn (Google Form) với ảnh chụp 2 bản: thích bản nào để dùng mỗi ngày, bản nào để khoe.

## Nguồn chính

- NN/g aesthetic-usability: https://www.nngroup.com/articles/aesthetic-usability-effect/
- Epstein et al., CHI 2016: https://pmc.ncbi.nlm.nih.gov/articles/PMC5428074
- Google Material 3 Expressive: https://research.google/pubs/usability-hasnt-peaked-exploring-how-expressive-design-overcomes-the-usability-plateau/
- BeReal: https://techcrunch.com/2023/09/29/bereal-pushes-back-at-report-that-its-losing-steam-says-it-now-has-25m-daily-users
- Locket ở Việt Nam: https://advertisingvietnam.com/locket-va-su-dich-chuyen-sang-intimate-social-gen-z-thu-hep-khong-gian-chia-se-thuong-hieu-can-hoc-cach-hien-dien-tinh-te-hon-p27883 , https://vietcetera.com/amp/vn/cung-locket-he-tu-tuong-dung-mang-xa-hoi-de-song-that-co-gi-ma-hot
- Gen Z và film/cổ điển: https://vneconomy.vn/san-pham-loi-thoi-tao-doanh-thu-lon-nho-gen-z.htm
- Sticker, scrapbook: https://advertisingvietnam.com/article/tu-sticker-den-tui-tote-vi-sao-gen-z-me-man-merchandise-thuong-hieu-p26158 , https://tienphong.vn/gen-z-cap-nhat-xu-huong-moi-nho-ai-to-mau-profile-dan-so-tong-ket-chuyen-di-post1840379.tpo
- Q&Me app popularity 2025: https://qandme.net/en/report/viet-nam-mobile-app-popularity-2025.html
