# Ourney — Danh sách câu hỏi đã hỏi khách hàng (kèm các lựa chọn)

> Toàn bộ câu hỏi đã hỏi trong buổi lấy yêu cầu và review SDS (2026-10-22), theo đúng thứ tự đã hỏi. Mỗi câu kèm **đủ các lựa chọn đã đưa ra cùng mô tả**, đúng như lúc hỏi. **Không kèm câu trả lời của khách hàng.**
> - Câu "chọn nhiều" có ghi chú. Mọi câu đều có thêm ô "Other" để tự nhập câu trả lời.
> - Câu nào phải hỏi lại vẫn được ghi, kèm nhãn *(hỏi lại)*.
>
> Tổng: **95 câu hỏi lựa chọn** + **6 câu hỏi xác nhận quy trình** (Phần E).

---

## Phần A — Lấy yêu cầu ban đầu

### Đợt 1

**1. Người dùng chính anh/chị muốn phục vụ đầu tiên là ai? (để chọn nhóm dogfood và phong cách được làm kỹ nhất)**
- **Nhóm bạn học chung**: Sinh viên/người đi làm 18–28 học tiếng Anh, IELTS, đọc sách cùng 3–5 người bạn. Phong cách 2 (Accountability Squad).
- **Người giảm cân riêng tư**: Chủ yếu đi một mình, cần riêng tư tuyệt đối cho ảnh cơ thể và số kg. Phong cách 1.
- **Cặp đôi**: Hai người cùng giữ một thói quen (nấu ăn, yêu xa, tiết kiệm). Phong cách 4.
- **Nhóm bạn đi du lịch**: Hành trình ngắn 3–7 ngày, cuối chuyến có recap. Phong cách 3.

**2. Với 6 phong cách giao diện, bản phát hành đầu tiên nên làm thế nào?**
- **Làm kỹ 1–2 phong cách**: Các phong cách còn lại dùng giao diện mặc định. Đội 5 người làm xong nhanh hơn, dễ đo xem người dùng có thích không.
- **Làm đủ cả 6**: Đúng theo kế hoạch trong TASKS.md, khoảng 3–4 tuần, khối lượng thiết kế và test gấp nhiều lần.
- **1 giao diện, chỉ đổi màu**: Dùng chung một bố cục, mỗi loại hành trình chỉ đổi màu và icon. Rẻ nhất, mất đi phần cá tính của từng loại.

**3. Phong cách giao diện có nên gắn cứng với loại hành trình không?**
- **Gắn cứng theo mẫu**: Chọn mẫu Giảm cân thì luôn ra phong cách 1. Đơn giản, đúng như code hiện tại.
- **Người dùng tự chọn**: Ví dụ hành trình tự đặt nhưng muốn giao diện film (phong cách 3). Linh hoạt hơn, nhưng mọi phong cách phải chạy được với mọi loại dữ liệu.
- **Gợi ý theo mẫu, đổi được**: Mặc định theo mẫu, có thể đổi trong cài đặt của hành trình.

**4. Anh/chị đã mua hoặc sắp mua tài khoản Apple Developer ($99/năm) chưa?**
- **Đã mua / mua ngay**: Mở được TestFlight, push (nudge bạn bè), widget màn hình chính, universal link. Nút Nudge trong thiết kế làm được.
- **Chưa, để sau**: Giữ đúng SRS: .ipa chưa ký, hết hạn sau 7 ngày, không push. Phải bỏ nút Nudge khỏi thiết kế.
- **Chưa quyết**: Thiết kế cả hai trạng thái: có push và không có push.

### Đợt 2

**5. "Chia sẻ câu chuyện với mọi người" nghĩa là ai được xem hành trình của một người?**
- **Chủ yếu ra mạng xã hội**: Trong app chỉ có bạn thân/nhóm. Người lạ xem qua thiệp chia sẻ hoặc link chỉ đọc trên Instagram, TikTok, Facebook. Đây là hướng hiện tại.
- **Có feed công khai trong app**: Ai cũng được xem hành trình công khai của người khác, follow, khám phá theo lĩnh vực. App sẽ thành mạng xã hội, cần thêm kiểm duyệt nội dung.
- **Cả hai, người dùng tự chọn**: Mỗi hành trình có 3 mức: riêng tư, bạn bè/nhóm, công khai. Hành trình công khai hiện trong mục Khám phá.

**6. Vì đang ở giai đoạn thiết kế, tôi nên thiết kế bản nào?**
- **Bản lý tưởng, có đánh dấu**: Thiết kế đủ nudge, push, widget, clip, sau đó gắn nhãn tính năng nào thuộc v1, v2. Code làm dần theo nhãn.
- **Chỉ đúng phạm vi v1**: Bỏ mọi thứ cần Apple trả phí (nudge, widget, push).

**7. Cặp đôi nên là một mẫu hành trình riêng hay tự nhận ra?**
- **Mẫu riêng "Cặp đôi"**: Màn tạo hành trình có thẻ Cặp đôi, luôn là nhóm đúng 2 người. Rõ ràng, dễ hiểu.
- **Tự nhận khi nhóm 2 người**: Bất kỳ hành trình nhóm nào chỉ có 2 người thì chuyển sang giao diện cặp đôi. Đây là cách code đang làm.

**8. Anh/chị muốn nhận sản phẩm thiết kế ở dạng nào?** *(chọn nhiều)*
- **Tài liệu SRS**: Đặc tả yêu cầu đầy đủ có mã FR, user flow, danh sách màn hình.
- **Wireframe / sơ đồ luồng**: Sơ đồ các màn và cách đi từ màn này sang màn khác.
- **Prototype bấm thử được**: Trang HTML mô phỏng app để bấm thử trên điện thoại.
- **Figma**: Thiết kế trong Figma cho đội dev.

### Đợt 3

**9. Thiết kế đang vẽ những dữ liệu app chưa thu thập. Phần nào anh/chị muốn có?** *(chọn nhiều)*
- **Địa điểm + thời tiết**: Tự lấy khi chụp, dùng cho tem film du lịch (Đà Lạt · 18°C) và bản đồ chuyến đi.
- **Đồng hồ bấm giờ học**: Bấm bắt đầu/kết thúc phiên học trong app, hết giờ thì mở camera. Nếu không chọn thì người dùng tự nhập số phút.
- **Số liệu tập luyện**: Quãng đường, pace, thời gian buổi tập. Nhập tay hoặc lấy từ Apple Health/Google Fit.
- **Nhiều chỉ số tự đặt**: Hành trình tự đặt có 1–3 chỉ số (ví dụ số trang đọc, số cốc nước). Hiện tại chỉ cho tối đa 1 chỉ số.

**10. Mỗi ngày một người được check-in những gì cho một hành trình?**
- **1 ảnh hoặc clip ≤5s**: Giữ ý "mỗi ngày một khoảnh khắc", thêm clip ngắn như ý ban đầu của dự án.
- **Chỉ 1 ảnh**: Đúng như hiện tại. Đơn giản nhất.
- **Nhiều ảnh/clip mỗi ngày**: Mỗi ngày là một album nhỏ. Hợp với du lịch, nhưng phá cơ chế "một ngày một ảnh" và các lưới lịch.

**11. Trong hành trình nhóm hoặc cặp đôi, có được xem ảnh hôm nay của người khác trước khi mình chụp không?**
- **Xem được ngay**: Như bản thiết kế Cặp đôi: nửa khung là ảnh của người kia, tạo cảm hứng để mình chụp.
- **Chụp rồi mới xem**: Kiểu BeReal: ảnh của bạn bị làm mờ đến khi mình check-in. Tạo động lực check-in mạnh hơn.
- **Chủ nhóm tự chọn**: Chọn một trong hai kiểu khi tạo hành trình.

**12. Sau này có thêm phong cách mới, anh/chị định kiếm tiền thế nào?**
- **Chưa kiếm tiền**: Miễn phí hoàn toàn. Thiết kế không cần màn thanh toán.
- **Bán phong cách / gói Pro**: 6 phong cách miễn phí, phong cách mới hoặc thiệp đẹp hơn thuộc gói trả phí. Cần thiết kế cửa hàng và paywall.
- **Chưa quyết**: Chừa chỗ trong thiết kế nhưng chưa vẽ paywall.

### Đợt 4

**13. Một ngày có nhiều ảnh/clip thì ô của ngày đó trên dòng thời gian hiện ảnh nào?**
- **Tự chọn ảnh bìa**: Mặc định là ảnh đầu tiên, người dùng đổi được. Ô ngày có số nhỏ "+3", chạm vào thì mở album của ngày.
- **Luôn là ảnh mới nhất**: Đơn giản, không cần thao tác thêm.
- **Ghép collage tự động**: Ô ngày tự ghép 2–4 ảnh. Sinh động hơn nhưng khó nhìn khi ô nhỏ.

**14. "Unlock để mở nhiều tính năng hơn": những thứ nào nên cần mở khóa?** *(chọn nhiều)*
- **Phong cách & mẫu thiệp mới**: 6 phong cách hiện tại miễn phí, phong cách ra sau phải mở khóa.
- **Xuất video recap**: Video timelapse/montage cả hành trình, không watermark.
- **Nhiều hành trình hơn**: Miễn phí tối đa 3 hành trình đang chạy, trả phí thì không giới hạn.
- **Lưu trữ & chất lượng**: Ảnh gốc chất lượng cao, clip dài hơn, nhóm lớn hơn 10 người.

**15. Khi mở app, màn đầu tiên nên là gì?**
- **Camera (như hiện tại)**: Kiểu Locket: chụp ngay, nhanh nhất để check-in.
- **Trang hành trình**: Thấy tất cả hành trình, tiến độ và hôm nay còn thiếu gì, rồi mới chụp. Hợp với ý "nơi lưu trữ" hơn.
- **Camera nếu hôm nay chưa chụp**: Chưa check-in thì mở camera, đã check-in rồi thì mở trang hành trình.

**16. Thiết kế cho những thiết bị nào?** *(chọn nhiều)*
- **Điện thoại iOS + Android**: Bắt buộc, đã có.
- **Widget màn hình chính**: Hiện ảnh mới nhất của nhóm/cặp đôi kiểu Locket, đếm streak.
- **Trang web xem link**: Trang web chỉ đọc khi người lạ bấm link chia sẻ từ mạng xã hội.
- **Máy tính bảng**: Giao diện 2 cột cho iPad/tablet.

### Đợt 5

**17. Đề xuất màn đầu khi có nhiều hành trình có ổn không?** (Đề xuất được trình bày trước câu hỏi: còn ≥ 1 hành trình chưa check-in hôm nay thì mở camera, chip chọn sẵn hành trình chưa chụp, ưu tiên cái có chuỗi sắp đứt, phía trên có dải nhỏ "Hôm nay: 1/3 đã xong", chạm để đổi; cả 3 đều xong thì mở trang hành trình.)
- **Đồng ý**: Còn hành trình chưa check-in thì mở camera, chọn sẵn cái chuỗi ngày sắp đứt. Xong hết thì mở trang hành trình.
- **Chọn trước rồi mới chụp**: Hiện bảng chọn nhanh các hành trình chưa chụp, chạm một cái thì mở camera.
- **Chụp rồi mới gán**: Chụp trước, sau đó tick một hoặc nhiều hành trình để đăng ảnh vào.

**18. Bản thiết kế đầu tiên có thêm mẫu hành trình mới từ kết quả research không?**
- **Thêm mẫu dùng lại phong cách**: Chạy bộ, đọc sách, tiết kiệm, cai thói quen xấu, dùng lại 6 phong cách đang có. Không tốn thêm thiết kế giao diện.
- **Chỉ giữ 6 mẫu**: Mẫu mới để đợt sau. Trong tài liệu chỉ chừa chỗ cho cửa hàng mẫu.
- **Thêm cả phong cách mới**: Thiết kế thêm phong cách cho skincare, mang thai/em bé, thú cưng, cải tạo nhà. Tài liệu dài gấp đôi.

**19. Phần vỏ chung của app (trang hành trình, cài đặt, hồ sơ) nên mang cảm giác thế nào?**
- **Giữ như hiện tại**: Nền kem ấm #F6F2EA / đen #0F0F14, điểm nhấn coral #FF4D6D, kiểu tạp chí, trẻ trung.
- **Trung tính hơn**: Đen trắng tối giản để 6 phong cách nổi bật, kiểu Apple/Notion.
- **Vui nhộn, nhiều màu**: Kiểu Duolingo/Locket: nút dày, màu rực, nhiều chuyển động.

**20. Ngôn ngữ và thị trường?**
- **Việt + Anh, VN trước**: Mặc định tiếng Việt, có tiếng Anh, như hiện tại.
- **Quốc tế ngay từ đầu**: Tiếng Anh là chính, thiết kế sẵn cho nhiều ngôn ngữ. Các bản thiết kế hiện đang dùng chữ tiếng Anh.

### Đợt 6

**21. Những phong cách mới nào cần có trong bản thiết kế? (có thể ghi thêm ở ô Other: kỹ năng sáng tạo, chạy bộ…)** *(chọn nhiều)*
- **Skincare / Glow-up**: Ảnh mặt chụp cùng góc, cùng ánh sáng, thiệp before/after. Riêng tư cao.
- **Mang thai & em bé**: Ảnh theo tuần/tháng, thiệp theo tháng, màu pastel. Ảnh trẻ em nên riêng tư tuyệt đối.
- **Thú cưng lớn lên**: Ảnh cùng góc, cân nặng, xuất timelapse.
- **Cải tạo nhà / DIY**: Ảnh cùng góc phòng, chi phí, % hoàn thành, kéo trượt before/after.

**22. Phần vỏ mới của app nên mang cảm giác nào?**
- **Nhật ký ấm, hoài niệm**: Giống một cuốn album/sổ lưu niệm: giấy, chữ serif, ảnh là trung tâm. Hợp với ý "nơi lưu trữ hành trình".
- **Sạch, cao cấp**: Kiểu Apple Journal/Photos: nhiều khoảng trắng, để 6+ phong cách tự tỏa sáng.
- **Năng động Gen Z**: Kiểu Locket/BeReal: camera là trung tâm, nút to, màu mạnh, nhiều chuyển động.

**23. Khi một hành trình kết thúc, người dùng nhận được gì?** *(chọn nhiều)*
- **Video recap**: Timelapse/montage cả hành trình. Bản không watermark nằm trong gói trả phí.
- **Thiệp tổng kết + lưu vào kệ**: Hành trình xong được xếp vào "kệ hành trình" như một cuốn album để xem lại.
- **Tiếp tục / mùa 2**: Gia hạn thêm ngày hoặc bắt đầu chặng tiếp theo, giữ lại lịch sử.
- **Sách ảnh in**: Đặt in photobook như Polarsteps. Chỉ vẽ chỗ, chưa làm.

**24. Ngoài ảnh, mỗi lần check-in có ghi nhật ký không?**
- **Caption ngắn + cảm xúc**: Caption ≤140 ký tự và chọn nhanh một cảm xúc. Giữ được tốc độ 3 chạm.
- **Ghi chú dài tùy chọn**: Thêm được đoạn nhật ký dài sau khi đăng, giống Day One.
- **Chỉ caption ngắn**: Giữ như hiện tại.

---

## Phần B — Chốt 11 giả định của SDS v0.1 (§15)

### Đợt 1

**25. Q1 — Có tính năng "Nhập hành trình đã qua" không? (chọn ảnh cũ trong thư viện, app tự xếp vào đúng ngày theo ngày chụp)**
- **Có, không tính streak**: Nhập được, hành trình có nhãn "Imported", phần quá khứ không tính chuỗi ngày (không streak giả).
- **Có, tính cả streak**: Ngày nào có ảnh thì tính vào chuỗi ngày như bình thường.
- **Không cần**: Chỉ ghi lại hành trình từ hôm nay trở đi.

**26. Q2 — Ai quyết định việc được xem ảnh của bạn trong nhóm/cặp đôi trước khi mình chụp?**
- **Chủ nhóm đặt cho cả nhóm**: Cả nhóm cùng một luật, công bằng, dễ hiểu.
- **Mỗi người tự đặt**: Mỗi người tự chọn có muốn tự "khóa" mình cho đến khi chụp hay không.
- **Người đăng quyết định**: Mỗi người chọn ảnh của MÌNH có bị che với người chưa chụp hay không.

**27. Q3 — Clip được dài tối đa bao nhiêu?**
- **5s free, 15s Plus**: Giữ cảm giác nhanh kiểu Locket, Plus dài hơn.
- **10s free, 30s Plus**: Đủ cho một đoạn tập luyện, một góc du lịch.
- **3s free, 10s Plus**: Rất ngắn, hợp để ghép video kiểu "1 giây mỗi ngày".

**28. Q4 — Số ảnh/clip mỗi ngày cho một hành trình có giới hạn không?**
- **Free 10, Plus không giới hạn**: Đủ cho hầu hết người dùng, là lý do để lên Plus với người chụp nhiều (du lịch).
- **Không giới hạn cho ai**: Đơn giản, không cần thiết kế trạng thái hết lượt.
- **Free 5, Plus 50**: Giới hạn chặt hơn để tiết kiệm lưu trữ.

### Đợt 2

**29. Q5 — Mỗi người được chạy tối đa bao nhiêu hành trình cùng lúc?**
- **Free 3, Plus không giới hạn**: Giữ giới hạn hiện tại, là thêm một lý do để lên Plus.
- **3 cho tất cả**: Giữ đúng như hiện tại, Plus không liên quan.
- **Không giới hạn**: Ai cũng tạo bao nhiêu tùy thích. Bảng chọn hôm nay có thể rất dài.

**30. Q6 — Với Mang thai & em bé (ảnh trẻ em): nhóm "Gia đình" tối đa 10 người và tắt link công khai mặc định, đồng ý không?**
- **Đồng ý**: Gia đình ≤10 người, link tắt mặc định, muốn bật phải xác nhận thêm.
- **Cấm hẳn link**: Hành trình em bé không bao giờ có link công khai, chỉ chia sẻ thiệp/video.
- **Như mọi hành trình khác**: Không có quy tắc riêng.

**31. Q7 — Cải tạo nhà có chia nhiều "khu vực" (bếp, phòng ngủ, ban công) trong một dự án không?**
- **Có khu vực**: Mỗi ảnh gắn một khu vực, mỗi khu vực có before/after và % riêng.
- **Một khu vực**: Mỗi hành trình là một góc/phòng. Muốn nhiều phòng thì tạo nhiều hành trình.

**32. Q8 — Có tính năng "Tạm dừng hành trình" (ốm, đi công tác…) mà không mất chuỗi ngày không?**
- **Có, ≤7 ngày/lần**: Tạm dừng tối đa 7 ngày mỗi lần, ngày tạm dừng không tính lỡ.
- **Streak freeze kiểu Duolingo**: Không tạm dừng cả hành trình, mỗi tuần có 1–2 lượt "đóng băng" để giữ chuỗi.
- **Không**: Lỡ là đứt chuỗi, giữ đúng tinh thần thử thách.

### Đợt 3

**33. Q9 — Giá Ourney Plus dự kiến? (tham khảo, chưa kiểm chứng: Locket Gold ~$3/tháng, Polarsteps Plus ~$35/năm)**
- **~$2.99/tháng · $19.99/năm**: VN khoảng 49k/tháng · 299k/năm. Ngang Locket, dễ mua với Gen Z.
- **~$4.99/tháng · $34.99/năm**: VN khoảng 99k/tháng · 599k/năm. Ngang Polarsteps.
- **Chưa chốt giá**: Thiết kế paywall với giá giữ chỗ, chốt sau.

**34. Q8b — Streak freeze hoạt động thế nào?**
- **2/tháng free, nhiều hơn với Plus**: Tự dùng khi lỡ một ngày. Plus có 5/tháng.
- **Kiếm bằng chuỗi ngày**: Cứ đủ 7 ngày liên tiếp thì được thêm 1 lượt, giữ tối đa 3.
- **1/tuần cho tất cả**: Đơn giản, không dính tới Plus.

**35. Q10 — Giọng văn và cách xưng hô của app?**
- **Ấm, khích lệ, ngắn**: Như một người bạn đồng hành: "Ngày 12 rồi, chụp một tấm nhé." Tiếng Việt xưng "bạn". Hợp cả Gen Z lẫn 9x.
- **Trẻ trung, lầy lội**: Kiểu Duolingo: "Chuỗi 21 ngày sắp toang 🔥". Hợp Gen Z, có thể kén người lớn tuổi.
- **Trang nhã, tối giản**: Kiểu Apple: "Ngày 12. Sẵn sàng chụp."

**36. Q11 — Ai sẽ vẽ board thiết kế cho 4 phong cách mới (Glow Ritual, Little Milestones, Paw Growth, Blueprint Makeover)?**
- **AI vẽ từ tài liệu**: Anh/chị đưa §6.4 cho AI tạo ảnh board giống 6 board hiện có. Tôi sẽ viết sẵn prompt cho từng board.
- **Designer trong đội**: Một người trong đội vẽ trên Figma.
- **Claude vẽ mockup HTML**: Tôi dựng mockup bấm thử được cho 4 phong cách để anh/chị duyệt.

---

## Phần C — Câu hỏi từ 2 reviewer (Review A: UX, Review B: visual)

### Đợt 1/6

**37. Chuỗi ngày và lượt freeze tính theo cách nào? (A05/A16)**
- **Freeze chung, streak riêng**: Kho freeze chung cho tài khoản, lỡ ngày ở hành trình nào thì tự dùng. Trong nhóm/cặp đôi, mỗi người có chuỗi riêng.
- **Freeze theo từng hành trình**: Mỗi hành trình có kho freeze riêng (2 lượt/tháng mỗi hành trình). Nhiều hành trình thì có nhiều freeze.
- **Thêm chuỗi chung của nhóm**: Ngoài chuỗi cá nhân, nhóm/cặp đôi có thêm "chuỗi đủ mặt" (ngày nào cả nhóm đều chụp). Freeze chung cho tài khoản.

**38. Tab Squad hiển thị gì với người chỉ có hành trình solo? (A12)**
- **Giữ tab, trạng thái rỗng mời**: Luôn có tab Squad. Chưa có nhóm thì hiện màn mời: tạo nhóm, nhập mã, mời người yêu. Dock luôn 3 tab như luật hiện tại.
- **Đổi thành tab khác khi solo**: Chưa có nhóm thì tab phải thành "Kệ" (hành trình đã xong), có nhóm thì thành Squad.

**39. Khi có rất nhiều hành trình, người dùng có được chọn màn mở app không? (A02)**
- **Có cài đặt, mặc định theo D9**: Mặc định: bảng chọn hôm nay. Cài đặt cho phép "Mở vào camera" hoặc "Mở vào Hub". Đóng bảng mà không chọn thì về Hub.
- **Không, giữ D9 cố định**: Luôn theo D9. Đóng bảng mà không chọn thì về Hub.

**40. Gói miễn phí được lưu bao nhiêu, và khi đầy thì sao? (A07)**
- **Không giới hạn số ảnh, Plus = ảnh gốc**: Free lưu không giới hạn ở chất lượng nén (1080px). Plus lưu ảnh gốc. Không bao giờ chặn đăng.
- **Free có hạn mức GB**: Ví dụ free 2GB, đầy thì vẫn đăng được nhưng chỉ lưu trên máy, có thanh dung lượng và mời lên Plus.
- **Chưa chốt**: Thiết kế cả màn thông báo gần đầy/đầy, con số để trống.

### Đợt 2/6

**41. "Cả nhóm check-in đủ ngày thì được 1 lượt freeze cho journey". "Đủ ngày" nghĩa là gì?**
- **Đủ mặt 7 ngày liền**: Cả nhóm cùng check-in 7 ngày liên tiếp thì được +1 freeze (giống luật cá nhân).
- **Đủ mặt 1 ngày = +1**: Ngày nào tất cả thành viên đều chụp thì được +1 freeze. Rất hào phóng, cần giới hạn số lượt giữ tối đa.
- **Đủ mặt cả tuần lịch**: Tuần (T2–CN) nào không ai lỡ ngày nào thì +1 freeze.

**42. Khi đã có nhóm (tab phải là Squad), Kệ hành trình đã xong nằm ở đâu?**
- **Trong Hub (Journeys)**: Hub có 2 tab con trên cùng: "Đang đi" / "Kệ". Khi solo, tab phải cũng mở thẳng Kệ. Kệ luôn ở một chỗ quen thuộc.
- **Trong hồ sơ**: Kệ nằm trong trang hồ sơ cá nhân, giống một bộ sưu tập.
- **Giữ tab phải luôn là Squad**: Bỏ ý đổi tab. Kệ chỉ nằm trong Hub, Squad rỗng thì hiện màn mời.

**43. 4 phong cách mới có nhịp check-in riêng không? (A10) Ví dụ: em bé chụp theo tháng, sửa nhà chỉ chụp ngày có làm.**
- **Có nhịp linh hoạt**: Khi tạo hành trình chọn nhịp: hằng ngày / X lần mỗi tuần / hằng tuần / hằng tháng. Chuỗi tính theo nhịp đó. Áp dụng cho mọi mẫu.
- **Luôn hằng ngày**: Mọi mẫu đều là mỗi ngày một lần, dùng freeze cho ngày nghỉ.
- **Chỉ mẫu đặc thù**: Em bé theo tuần/tháng, sửa nhà không tính chuỗi. Các mẫu khác hằng ngày.

**44. Ảnh trẻ em và ảnh cơ thể khi bật link công khai (A17/B-20). D20 nói "như mọi hành trình"; reviewer cảnh báo rủi ro.**
- **Giữ D20 + cảnh báo**: Vẫn bật được như mọi hành trình, nhưng hiện một sheet cảnh báo khi bật, ảnh xem trước link (OG) tự làm mờ.
- **Giữ D20, không thêm gì**: Đúng như mọi hành trình khác.
- **Đổi: xác nhận 2 bước**: Mẫu em bé/giảm cân/glow-up cần xác nhận thêm một bước mới bật được link.

### Đợt 3/6

**45. Tab phải của dock khi người dùng chưa có nhóm?**
- **A: Solo = Kệ, có nhóm = Squad**: Chưa có nhóm: tab phải là Kệ (có nút nhỏ "Tạo nhóm / Nhập mã"). Có nhóm: tab phải là Squad. Kệ luôn còn trong Hub. Dock luôn 3 nút.
- **B: Ẩn hẳn khi solo**: Chưa có nhóm thì dock chỉ còn Journeys + nút chụp. Tạo nhóm/nhập mã nằm trong Hub. Phải sửa luật dock 3 tab trong CLAUDE.md.

**46. Có thêm cổng tuổi và lý do báo cáo "An toàn trẻ em" không? (B-21) App Store/Google Play thường yêu cầu với app có nội dung người dùng tạo.**
- **Thêm cả hai ở v1**: Đăng ký hỏi ngày sinh (từ 13 tuổi, dưới 18 có hạn chế link công khai) + lý do báo cáo "Child safety".
- **Chỉ thêm lý do báo cáo**: Không hỏi tuổi, chỉ thêm lý do báo cáo.
- **Không thêm**: Giữ như tài liệu hiện tại.

**47. Widget và thông báo trên màn khóa có thể lộ hành trình nhạy cảm (ảnh cơ thể, em bé, tên "Giảm cân") (B-19). Mặc định thế nào?**
- **Ẩn với mẫu nhạy cảm**: Giảm cân, glow-up, em bé: widget hiện ảnh mờ, thông báo không ghi tên hành trình ("1 hành trình đang chờ bạn"). Bật lại được trong cài đặt.
- **Hiện bình thường**: Người dùng tự tắt nếu muốn.
- **Ẩn với mọi hành trình**: Không bao giờ hiện ảnh/tên trên màn khóa nếu người dùng chưa bật.

**48. Chủ nhóm rời đi, người rời nhóm, và mùa 2 của nhóm xử lý thế nào? (A09/A23)**
- **Theo SRS + mùa 2 mời lại**: Chủ rời thì chuyển quyền cho người vào sớm nhất. Ảnh của người rời nhóm bị ẩn (vào lại thì hiện). Mùa 2 gửi lời mời, ai đồng ý mới vào.
- **Ảnh người rời vẫn giữ**: Như trên nhưng ảnh của người đã rời vẫn nằm trong kỷ niệm của nhóm (trừ khi họ tự xóa).

### Đợt 4/6

**49. Đề xuất tab phải ở trên (luôn là Squad, trang mời gọi khi chưa có nhóm, Kệ trong Hub) có ổn không?** (Đề xuất được trình bày trước câu hỏi: tab phải luôn là Squad, không đổi theo việc có nhóm hay chưa; chưa có nhóm thì tab Squad là trang mời gọi với 3 thẻ to `Rủ bạn đi cùng` · `Rủ người ấy (Couple)` · `Nhập mã mời` và minh họa tường ảnh nhóm; Kệ luôn ở Hub dạng tab con `Đang đi | Kệ`.)
- **Đồng ý đề xuất**: Tab phải luôn là Squad. Chưa có nhóm thì là trang mời gọi. Kệ nằm ở Hub (Đang đi | Kệ).
- **Vẫn đổi thành Kệ khi solo**: Chấp nhận tab đổi tên khi có nhóm đầu tiên.

**50. Đăng một ảnh cho nhiều hành trình cùng lúc: phần nào dùng chung? (A04)**
- **Ảnh + caption chung, chỉ số riêng**: Ảnh, caption, cảm xúc dùng chung. Chỉ số và sticker riêng theo từng hành trình. Đăng từ hành trình riêng tư sang nhóm thì hiện cảnh báo "Ảnh này sẽ hiện với nhóm X".
- **Chỉ ảnh chung**: Mỗi hành trình có caption, cảm xúc, chỉ số riêng, phải nhập từng cái.
- **Cấm trộn riêng tư với nhóm**: Ảnh + caption chung, nhưng không cho đăng cùng lúc vào hành trình riêng tư và hành trình nhóm.

**51. Hành trình kết thúc khi đạt thấp (ví dụ dưới 50% số ngày) thì màn kết thúc thế nào? (A23)**
- **Vẫn ăn mừng, giọng khác**: Vẫn có recap và thiệp, nhưng lời văn ghi nhận nỗ lực ("14 ngày vẫn là 14 ngày 💪"), không confetti lớn, gợi ý mùa 2.
- **Giống hệt hoàn thành**: Không phân biệt, ai cũng được ăn mừng như nhau.

**52. Ở v1 chưa có universal link, bạn bè chưa cài app bấm link mời thì sao? (A08)**
- **Trang web mời + mã**: Link mở trang web nhỏ: tên hành trình, người mời, mã 8 ký tự, nút tải app. Cài xong mở app, app tự dán mã từ clipboard.
- **Chỉ chia sẻ mã ở v1**: Không có link, chỉ gửi mã 8 ký tự kèm lời dẫn tải app.

### Đợt 5/6

**53. Người dùng có được chọn giọng văn thông báo không? (A26) Giọng lầy lội có thể kén người 35–45 tuổi.**
- **Có: Lầy / Nhẹ nhàng**: Mặc định Lầy. Cài đặt có lựa chọn "Nhẹ nhàng". Mẫu nhạy cảm luôn dùng giọng ấm.
- **Không, một giọng**: Toàn app lầy lội, chỉ mẫu nhạy cảm dùng giọng ấm (như §3.6 hiện tại).

**54. Có chấp nhận ngoại lệ vùng chạm và cỡ chữ không? (A19) Nút chụp dạng viên thuốc 56×40 thấp hơn 48dp; chữ Caption/Overline 12–13pt nhỏ hơn mức 16pt.**
- **Chấp nhận có điều kiện**: Viên 56×40 nhìn thấy nhưng vùng chạm vô hình vẫn 56×48. Chữ 12–13pt chỉ dùng cho nhãn phụ, không dùng cho nội dung cần đọc.
- **Không ngoại lệ**: Viên chụp cao 48. Chữ nhỏ nhất 14pt.

**55. 4 phong cách mới bị trùng tông (B-10/11): Glow Ritual gần Couple (hồng đào), Paw Growth cùng họ cam với Squad và Minimalist. Xử lý thế nào?**
- **Đổi tông cho khác hẳn**: Ví dụ Glow chuyển sang lilac/ngọc trai, Paw sang xanh lá cây/teal. Giám khảo sẽ đề xuất mã màu, anh/chị duyệt sau.
- **Giữ màu, khác bằng hình**: Giữ bảng màu hiện tại, phân biệt bằng kiểu khung, font, họa tiết.

**56. Chữ trên nút màu nhấn không đạt độ tương phản ở một số phong cách (B-02/03), ví dụ chữ trắng trên peach #D9776A chỉ ~3:1. Cách sửa?**
- **Chỉnh màu nhấn đậm hơn**: Giữ chữ trắng, làm màu nhấn đậm lên một chút cho đạt AA. Nút vẫn sặc sỡ.
- **Giữ màu, dùng chữ đậm màu**: Giữ đúng mã màu, chữ trên nút là màu tối (ink). Thêm token `onAccent` cho từng phong cách.

### Đợt 6/6

**57. Nút chụp nhỏ ở dock và chữ nhãn phụ: xử lý thế nào?** (Giải thích trước câu hỏi: ở các màn không phải camera, nút chụp giữa dock là viên thuốc cao 40, trong khi luật yêu cầu chỗ bấm cao ít nhất 48; luật chữ tối thiểu 16pt nhưng các nhãn phụ như "Day 12", giờ chụp đang dùng chữ 12–13pt.)
- **Nhìn nhỏ, bấm vẫn to**: Viên thuốc vẫn trông cao 40 cho gọn, nhưng vùng bấm thực tế rộng 48 (người dùng không thấy khác). Chữ 12–13pt chỉ cho nhãn phụ như giờ chụp, không cho nội dung chính.
- **Làm to hẳn**: Viên thuốc cao 48 thật. Chữ nhỏ nhất 14pt. Dễ dùng hơn cho người lớn tuổi, giao diện kém thanh thoát hơn.

**58. Đổi hành trình trên màn camera: có tự đổi camera trước/sau không? (B-06) Ví dụ Glow Ritual cần camera trước để chụp mặt, nhưng luật hiện tại là đổi hành trình không được khởi động lại camera.**
- **Mỗi hành trình nhớ camera riêng**: Mỗi hành trình nhớ lần cuối dùng camera trước hay sau (Glow mặc định trước). Chấp nhận chuyển camera mất ~0.3s có hiệu ứng mờ.
- **Giữ camera đang dùng**: Đổi hành trình không đổi camera. Người dùng tự bấm nút đổi. Glow chỉ hiện gợi ý "Dùng camera trước".

**59. Font trang trí cho từng phong cách? (B-12) Mỗi font thêm làm app nặng hơn, và cần hỗ trợ đầy đủ dấu tiếng Việt.**
- **Tối đa 4–5 font có dấu Việt**: Thêm vài font trang trí (serif, máy đánh chữ, tròn, monospace) dùng chung giữa các phong cách. Chỉ chọn font hỗ trợ đủ dấu tiếng Việt.
- **Chỉ 2 font hiện có**: Be Vietnam Pro + Bricolage Grotesque. Phong cách khác nhau bằng màu, hình khối, họa tiết.

**60. Các bản thiết kế mẫu cũ có lỗi (nhãn "3-tab", lịch 5 cột ở board 6, chỉ 15 khung phim ở board 3) (B-09). Xử lý thế nào?**
- **Vẽ lại board lỗi bằng AI**: Giám khảo viết prompt vẽ lại các board lỗi, kèm prompt dark cho cả 10 phong cách.
- **Chỉ ghi chú "không chép"**: Giữ board cũ, liệt kê lỗi để AI và dev không chép theo.

### Đợt 7

**61. Đổi sang hành trình khác trên màn camera, ống kính trước/sau xử lý thế nào?** *(hỏi lại câu 58)* (Giải thích trước câu hỏi: câu này không phải về filter, mà về ống kính trước (selfie) hay sau. Ví dụ đang ở hành trình Du lịch dùng camera sau, chuyển sang Skincare cần camera trước: app có tự lật không, hay giữ camera sau và để người dùng tự bấm lật?)
- **Tự lật theo hành trình**: Mỗi hành trình nhớ lần cuối dùng camera trước hay sau (Skincare mặc định camera trước). Đổi hành trình thì tự lật, màn hình mờ ~0.3s.
- **Giữ nguyên, tự bấm lật**: Đổi hành trình không lật camera. Skincare chỉ hiện gợi ý "Dùng camera trước".

**62. 6 ảnh thiết kế mẫu cũ có lỗi (chữ "3-tab", dấu "...", lịch 5 cột, 15 khung phim). Xử lý thế nào?** *(hỏi lại câu 60)* (Giải thích trước câu hỏi: "board" là 6 ảnh thiết kế mẫu trong `assets/design_personas/`. Ảnh do AI vẽ nên có lỗi, ví dụ thanh dưới có chữ "3-tab" thay cho icon, nút chụp có dấu "...", lịch 5 cột thay vì 7, tờ phim 15 khung thay vì 20. Khi đưa các ảnh này cho AI hay dev làm mẫu, họ có thể chép luôn lỗi.)
- **Vẽ lại bằng AI**: Giám khảo viết prompt để vẽ lại những ảnh có lỗi, kèm prompt bản nền tối cho cả 10 phong cách. Bộ ảnh mẫu sẽ sạch và đồng bộ.
- **Giữ ảnh, ghi danh sách lỗi**: Không vẽ lại, chỉ ghi rõ các lỗi để AI và dev biết mà không chép theo.

**63. Nhãn nổi trên khung camera (như "FILM ROLL 12/36", "Day 24") nên màu gì? (B-17) Board 3 và 6 đang dùng nhãn nền sáng, các board khác dùng nền tối trong mờ.**
- **Theo phong cách**: Phong cách nào hợp nền sáng (film, tối giản) thì dùng nền sáng, còn lại dùng nền tối. Luôn có viền/bóng để đọc được trên mọi ảnh.
- **Luôn nền tối trong mờ**: Mọi phong cách đều dùng nền tối trong mờ cho đồng bộ, dễ đọc nhất.

**64. Các ô chữ nhỏ nằm đè trên khung camera (ví dụ "Day 24") nên có nền màu gì? Ảnh chụp ra không bị dính các ô này.** *(hỏi lại câu 63)* (Giải thích trước câu hỏi: đây không phải filter, mà là các ô chữ nhỏ nằm đè lên khung camera; ảnh chụp ra không bị dính các ô này.)
- **Luôn nền tối trong mờ**: Mọi phong cách giống nhau: nền đen trong mờ, chữ trắng. Dễ đọc nhất trên mọi ảnh.
- **Theo phong cách**: Phong cách film/tối giản dùng nền sáng (kem/trắng), các phong cách khác nền tối. Có viền/bóng để luôn đọc được.

---

## Phần D — Câu hỏi còn mở của giám khảo (08-SDS-review §10)

### Đợt 1

**65. Q1 — Thời điểm trong ngày. Mốc cảnh báo chuỗi sắp đứt, giờ kết thúc một "ngày", và cách tính khi đi du lịch đổi múi giờ?**
- **Tự chọn · 0h · giờ máy**: Cảnh báo do người dùng chọn (mặc định 21:00). Ngày kết thúc lúc 00:00. Đi du lịch thì theo giờ điện thoại hiện tại.
- **Tự chọn · 3h sáng · giờ máy**: Giống trên, nhưng ngày kết thúc lúc 03:00 sáng hôm sau, cho người hay thức khuya.
- **21h cố định · 0h · múi giờ gốc**: Cảnh báo luôn lúc 21:00. Ngày kết thúc lúc 00:00. Tính theo múi giờ lúc tạo hành trình (như code hiện tại).

**66. Q2 — Với nhịp "X lần/tuần", "hằng tuần", "hằng tháng", chuỗi đếm thế nào và lịch hiển thị ra sao?**
- **Đếm theo kỳ, ô trung tính**: Chuỗi = số tuần/tháng đạt chỉ tiêu liên tiếp ("🔥 5 tuần"). Freeze cứu cả một kỳ bị lỡ. Ngày không bắt buộc hiện ô trung tính, không tính lỡ. Mặc định: Mang thai = hằng tuần, Em bé = hằng tháng, còn lại = hằng ngày.
- **Đếm theo kỳ, lưới tuần/tháng**: Như trên, nhưng nhịp tuần/tháng thì lịch chuyển sang lưới theo tuần/tháng thay vì lưới ngày.

**67. Q3 — Freeze của hành trình solo là quỹ chung hay riêng? Hành trình nhóm có thêm 2 lượt/tháng không? Lỡ nhiều ngày liền thì sao?**
- **Quỹ chung + nhóm chỉ có thưởng**: Solo: 2 lượt/tháng là quỹ chung của người dùng. Nhóm: chỉ có lượt thưởng khi cả nhóm đủ mặt 7 ngày, giữ tối đa 3. Lỡ nhiều ngày thì dùng liên tiếp đến khi hết lượt.
- **Mỗi hành trình một quỹ**: Mỗi hành trình (solo hay nhóm) có 2 lượt/tháng riêng, cộng lượt thưởng. Lỡ nhiều ngày thì dùng liên tiếp.
- **Chỉ cứu 1 ngày mỗi lần lỡ**: Quy tắc quỹ như lựa chọn 1, nhưng lỡ từ 2 ngày liền trở lên thì chuỗi vẫn đứt.

**68. Q4 — Trong lúc hành trình nhóm đang chạy, ô của từng thành viên trên tường ảnh có hiện chuỗi cá nhân không?**
- **Hiện chuỗi cá nhân nhỏ**: Mỗi ô có ✓ + giờ chụp + 🔥 chuỗi cá nhân. Chuỗi chung của nhóm nằm trên cùng.
- **Chỉ ✓ + giờ**: Không hiện chuỗi cá nhân khi đang chạy, chỉ hiện trong thống kê cuối hành trình. Giảm so bì.

### Đợt 2

**69. Q2 — Với nhịp không phải hằng ngày, lịch và chuỗi nên thế nào?** *(hỏi lại câu 66)* (Giải thích trước câu hỏi: ví dụ nhịp 3 lần/tuần, chụp T2, T4, T6 là đúng kế hoạch. Ô lỡ (viền nét đứt) nghĩa là "bạn đã bỏ lỡ", dùng cho nhịp hằng ngày; ô trung tính (xám nhạt, trơn) nghĩa là "nghỉ cũng không sao", dùng cho ngày không bắt buộc. Chuỗi tính theo kỳ, ví dụ "🔥 5 tuần liên tiếp đạt 3 lần".)
- **Ô trung tính + chuỗi theo kỳ**: Lịch vẫn theo ngày, ngày không bắt buộc là ô xám trơn. Chuỗi đếm theo tuần/tháng đạt chỉ tiêu. Freeze cứu một kỳ. Mặc định: Mang thai = hằng tuần, Em bé = hằng tháng, còn lại = hằng ngày.
- **Lưới theo kỳ + chuỗi theo kỳ**: Nhịp hằng tuần/tháng thì lịch thành lưới tuần/tháng (mỗi ô là 1 tuần/tháng). Nhịp X lần/tuần vẫn dùng lưới ngày với ô trung tính.

**70. Q3 — Đề xuất freeze ở trên (solo dùng quỹ chung, nhóm có quỹ riêng chỉ từ thưởng, lỡ nhiều ngày dùng liên tiếp, ưu tiên chuỗi dài nhất) có ổn không?** *(hỏi lại câu 67)* (Đề xuất được trình bày trước câu hỏi: solo dùng quỹ chung của người dùng, 2 lượt/tháng (Plus 5) + lượt thưởng mỗi chuỗi 7 ngày, tối đa 3; không chia mỗi hành trình một quỹ vì 20 hành trình sẽ có 40 lượt, freeze mất giá trị; nhóm có quỹ riêng của hành trình, chỉ kiếm khi cả nhóm đủ mặt 7 ngày (tối đa 3); lỡ nhiều ngày thì dùng liên tiếp đến khi hết; cùng ngày lỡ nhiều hành trình thì ưu tiên chuỗi dài nhất; mỗi lần dùng đều có thông báo.)
- **Đồng ý đề xuất**: Áp dụng đúng như mô tả ở trên.
- **Người dùng tự chọn cứu**: Như đề xuất, nhưng cùng ngày lỡ nhiều hành trình thì hỏi người dùng muốn cứu hành trình nào thay vì tự động.

**71. Q5 — Đăng check-in xong thì app làm gì?**
- **Nút Next + Done**: Ở lại màn "Đã đăng", có nút "Tiếp: Daily English" và "Xong". Người dùng tự bấm, không tự chuyển.
- **Đếm ngược 3s có nút Ở lại**: Tự chuyển sang hành trình chưa xong kế tiếp sau 3s, có nút "Ở lại".
- **Giữ 1.5s tự chuyển**: Như tài liệu hiện tại.

**72. Q6 — Cổng tuổi khi dùng app không cần tài khoản (chế độ khách)?**
- **Chỉ hỏi khi đăng ký**: Khách không có link công khai và nhóm nên không cần hỏi tuổi. Hỏi khi tạo tài khoản.
- **Hỏi ngay lần mở đầu**: Mọi người đều nhập ngày sinh ở onboarding.
- **Bỏ chế độ khách**: Bắt buộc đăng nhập mới dùng được.

### Đợt 3

**73. Q2 — Lịch của hành trình nhịp X lần/tuần, hằng tuần, hằng tháng hiển thị thế nào? (Chuỗi đếm theo tuần/tháng đạt chỉ tiêu.)** *(hỏi lại câu 66)* (Giải thích trước câu hỏi, kèm bảng ví dụ: hằng ngày — học tiếng Anh, lỡ khi hôm nào không chụp; X lần/tuần — gym 3 buổi/tuần, lỡ khi hết tuần chưa đủ 3 tấm; hằng tuần — mang thai mỗi tuần chụp 1 lần, lỡ khi hết tuần chưa có tấm nào; hằng tháng — em bé mỗi tháng chụp 1 lần, lỡ khi hết tháng chưa có tấm nào.)
- **PA2: ô theo kỳ**: Hằng tuần/hằng tháng: mỗi ô lịch là 1 tuần/1 tháng. X lần/tuần: lưới ngày, ngày không chụp là ô xám trơn, có đếm "2/3 tuần này".
- **PA1: luôn lưới ngày**: Mọi nhịp đều dùng lưới ngày. Ngày không bắt buộc hiện ô xám trơn.

**74. Q8 — Hành trình cặp đôi khi một người rời đi?**
- **Lưu trữ chỉ đọc**: Hành trình dừng lại và cất lên kệ của người còn lại, không chụp thêm.
- **Chờ người kia / mời lại**: Giữ chỗ, người còn lại vẫn chụp nửa của mình, có thể mời người kia quay lại.
- **Thành hành trình solo**: Tiếp tục như hành trình solo của người còn lại.

**75. Q9 — Người đăng bật "Che ảnh đến khi bạn chụp": chỉ che ảnh hôm nay, hay che cả những ngày cũ mà người xem chưa chụp?**
- **Chỉ hôm nay**: Qua ngày mới thì ảnh hôm qua hiện bình thường với mọi người.
- **Mọi ngày**: Ngày nào người xem không chụp thì ảnh ngày đó vẫn bị che vĩnh viễn.

**76. Q10 — Hành trình đã kết thúc có được gia hạn hoặc mở lại không?**
- **Chỉ mùa 2**: Đã kết thúc thì chỉ bắt đầu mùa 2. Gia hạn chỉ làm được khi hành trình còn đang chạy.
- **Mở lại trong 7 ngày**: Trong 7 ngày sau khi kết thúc vẫn mở lại/gia hạn được, sau đó chỉ còn mùa 2.

### Đợt 4

**77. Q2 — Đề xuất lưới theo đơn vị của nhịp có ổn không?** *(hỏi lại câu 66)* (Đề xuất được trình bày trước câu hỏi: hằng ngày — lưới ngày 7 cột; X lần/tuần — lưới ngày, mỗi hàng là 1 tuần, cuối hàng có dấu "3/3 ✓"; hằng tuần — lưới tuần, mỗi ô là 1 tuần; hằng tháng — lưới tháng, mỗi ô là 1 tháng. Kiểu xem Calendar có nút nhỏ đổi Ngày / Tuần / Tháng.)
- **Đồng ý đề xuất**: Lưới mặc định theo nhịp, có nút đổi Ngày/Tuần/Tháng.
- **Luôn lưới ngày**: Mọi nhịp đều lưới ngày, không có nút đổi.

**78. Q11 — Xóa tấm ảnh duy nhất của một ngày thì chuỗi của ngày đó thế nào?**
- **Ngày thành lỡ**: Ngày đó tính là lỡ, có thể tiêu freeze. Trước khi xóa, app cảnh báo "Xóa ảnh này sẽ làm mất ngày 12 trong chuỗi".
- **Vẫn giữ chuỗi**: Đã check-in thì tính, xóa ảnh sau đó không ảnh hưởng.

**79. Q12 — Trang web của link công khai có cho Google tìm thấy không? Công tắc "Cho phép link chia sẻ" mặc định bật hay tắt?**
- **Không lên Google · mặc định tắt**: Mọi trang link đều ẩn khỏi Google, chỉ ai có link mới xem được. Link phải tự bật.
- **Cho lên Google · mặc định tắt**: Hành trình đã bật link thì Google tìm thấy được (trừ mẫu nhạy cảm). Tăng người biết tới app.
- **Không lên Google · mặc định bật**: Solo mặc định có link sẵn để chia sẻ nhanh, nhưng không lên Google.

**80. Q13 — Clip ở gói miễn phí có bị nén giống ảnh không?**
- **Nén 1080p, Plus giữ gốc**: Giống quy tắc ảnh: miễn phí nén 1080p, Plus giữ chất lượng gốc.
- **Nén 720p, Plus 1080p+**: Tiết kiệm lưu trữ hơn cho gói miễn phí.

### Đợt 5 *(hỏi lại vì đợt 4 chưa nhận được câu trả lời)*

**81. Q2 — Lịch theo đơn vị của nhịp: hằng ngày và X lần/tuần dùng lưới ngày, hằng tuần dùng lưới tuần, hằng tháng dùng lưới tháng, có nút đổi Ngày/Tuần/Tháng. Đồng ý không?** *(hỏi lại câu 77)*
- **Đồng ý đề xuất**: Lưới mặc định theo nhịp, có nút đổi.
- **Luôn lưới ngày**: Mọi nhịp đều lưới ngày.

**82. Q11 — Xóa tấm ảnh duy nhất của một ngày thì chuỗi của ngày đó thế nào?** *(hỏi lại câu 78)*
- **Ngày thành lỡ (có cảnh báo)**: Trước khi xóa, app cảnh báo "Xóa ảnh này sẽ làm mất ngày 12 trong chuỗi". Xóa rồi thì ngày đó tính là lỡ, có thể tiêu freeze.
- **Vẫn giữ chuỗi**: Đã check-in thì tính, xóa ảnh sau đó không ảnh hưởng.

**83. Q12 — Trang web của link công khai có cho Google tìm thấy không? Công tắc "Cho phép link chia sẻ" mặc định bật hay tắt?** *(hỏi lại câu 79)*
- **Không lên Google · mặc định tắt**: Chỉ ai có link mới xem được. Người dùng phải tự bật link.
- **Cho lên Google · mặc định tắt**: Hành trình đã bật link thì Google tìm thấy được (trừ mẫu nhạy cảm). Giúp nhiều người biết tới app hơn.
- **Không lên Google · mặc định bật**: Hành trình solo có link sẵn để chia sẻ nhanh, nhưng không lên Google.

**84. Q13 — Clip ở gói miễn phí có bị nén giống ảnh không?** *(hỏi lại câu 80)*
- **Nén 1080p, Plus giữ gốc**: Giống quy tắc ảnh.
- **Nén 720p, Plus 1080p+**: Tiết kiệm lưu trữ hơn cho gói miễn phí.

### Đợt 6

> Trước đợt này có hiển thị bản xem trước màu: 4 phong cách mới ở nền sáng và tối, và 2 nút "Start journey" cho phương án A/B của Q14.

**85. Q14 — Nút chính màu thương hiệu (nền sáng) chọn phương án nào? (xem 2 nút "Start journey" ở trên)**
- **A: đậm + chữ trắng**: Màu hồng đậm #E11D48, chữ trắng. Giống các app quen thuộc, nhưng màu kém tươi hơn một chút.
- **B: tươi + chữ tối**: Giữ coral tươi #FF3B5C, chữ đen. Năng động, Gen Z hơn.

**86. Q15 — 6 phong cách cũ đang có nút màu tươi với chữ trắng không đọc rõ. Sửa thế nào?**
- **Giữ màu, chữ tối**: Giữ nguyên màu tươi của 6 phong cách, chữ trên nút đổi thành màu tối (như nút Sky và Park green ở trên). Giám khảo khuyên dùng.
- **Làm sậm màu, chữ trắng**: Đổi màu nút sậm hơn để giữ chữ trắng. Màu sẽ kém tươi, khác với các board hiện có.

**87. Q16 — Duyệt bảng màu mới cho 4 phong cách (Orchid · Sky · Park green · Cobalt) ở trên?**
- **Duyệt cả 4**: Dùng nguyên trạng.
- **Muốn đổi một vài cái**: Ghi rõ phong cách nào muốn đổi và muốn cảm giác thế nào ở ô Other.

**88. Q17 — Duyệt font trang trí? Fraunces (serif tạp chí), Baloo 2 (tròn, vui), Space Mono (kiểu máy đánh chữ), Barlow Condensed (chữ hẹp thể thao), Patrick Hand (viết tay, tùy chọn). Cả 5 đều có dấu tiếng Việt.**
- **Duyệt cả 5**: Gồm cả Patrick Hand cho nhãn viết tay của phong cách em bé.
- **Duyệt 4, bỏ Patrick Hand**: Gọn hơn, app nhẹ hơn.

### Đợt 7

**89. Q18 — Dòng thời gian của Glow Ritual (skincare) và Paw Growth (thú cưng) đang cùng kiểu "trục dọc" với phong cách 1 và 5, dễ nhìn giống nhau. Xử lý?**
- **Đổi cả hai**: Glow: lưới tuần 7 ô, cặp ảnh trước/sau ghim trên đầu. Paw: thước đo nằm ngang, cuộn trái–phải.
- **Chỉ đổi Glow**: Glow sang lưới tuần + cặp trước/sau, Paw giữ thước dọc.
- **Chỉ đổi Paw**: Paw sang thước ngang, Glow giữ trục dọc.
- **Giữ nguyên**: Khác nhau bằng trang trí và màu, bố cục vẫn là trục dọc.

**90. Q19 — Thiệp tổng kết của phong cách Tối giản ghi "% đều đặn". Con số này tính thế nào?**
- **Trên tổng mục tiêu**: 24 ngày xong / 30 ngày mục tiêu = 80%. Dễ hiểu.
- **Trên số ngày đã qua**: Đang ở ngày 25, đã xong 24 = 96%. Khích lệ hơn khi hành trình chưa xong.
- **Bỏ %, chỉ ghi 24/30**: Không dùng phần trăm.

**91. Q20 — Đã chụp xong mọi hành trình hôm nay, bấm nút chụp ở thanh dưới thì mở gì?**
- **Bảng hôm nay "Đã xong"**: Mở bảng chọn với trạng thái "Xong hết rồi 🎉" + danh sách hành trình để chụp thêm nếu muốn.
- **Camera hành trình gần nhất**: Mở thẳng camera của hành trình dùng gần nhất để chụp thêm.
- **Mở Hub**: Về trang hành trình.

**92. Q21 — Người dùng bấm "Bắt đầu" ngay mà không chỉnh gì thì thời lượng mặc định là bao nhiêu?**
- **Theo gợi ý của mẫu**: Mỗi mẫu một mặc định (ví dụ Chuyến đi 7 ngày, Giảm cân 30 ngày, Em bé 12 tháng, Sửa nhà không giới hạn).
- **Luôn 30 ngày**: Đơn giản, giống nhau mọi mẫu.
- **Không có ngày kết thúc**: Mặc định mở, người dùng tự kết thúc.

### Đợt 8

**93. Q23 — Đăng nhầm ảnh vào sai hành trình thì có được chuyển ảnh sang hành trình khác không? (Chuyển, không phải nhân bản, nên vẫn đúng luật mỗi ảnh một hành trình.)**
- **Cho chuyển**: Trong menu ảnh có "Chuyển sang hành trình khác". Ảnh rời khỏi hành trình cũ.
- **Không cho**: Đăng nhầm thì xóa và đăng lại.

**94. Q24 — Cài đặt giọng văn "Lầy / Nhẹ nhàng" áp dụng cho đâu?**
- **Mọi chữ trong app**: Thông báo, màn đã đăng, màn kết thúc, trạng thái rỗng. Nút bấm luôn rõ nghĩa, không đổi.
- **Chỉ thông báo**: Trong app luôn một giọng, chỉ thông báo đổi theo cài đặt.

**95. Q25 — Công tắc "ẩn ảnh/tên trên màn khóa và widget" đặt ở đâu?**
- **Cả hai**: Mặc định chung trong Cài đặt, mỗi hành trình ghi đè được trong cài đặt riêng của nó.
- **Từng hành trình**: Chỉ trong cài đặt của mỗi hành trình.
- **Toàn cục**: Một công tắc trong Cài đặt cho tất cả.

---

## Phần E — Câu hỏi xác nhận quy trình

**1. Anh/chị duyệt 11 giả định ở §15 ngay bây giờ chứ?**
- **Duyệt giả định**: Hỏi tôi lần lượt 11 giả định ở §15 để chốt rồi cập nhật tài liệu.
- **Vẽ board phong cách mới**: Vẽ thử board giao diện cho 4 phong cách mới (Glow Ritual, Little Milestones, Paw Growth, Blueprint Makeover).

**2. Commit tài liệu thiết kế lên một branch mới chứ?**
- **Commit lên branch**: Tạo branch docs/ui-design-spec và commit docs/07-SDS-ui-design.md.
- **Chưa commit**: Khoan commit, tôi đọc lại tài liệu trước.

**3. Anh/chị gửi lại tin nhắn giúp tôi được không?** (tin nhắn gửi thay cho câu trả lời Q2, Q11–Q13 mà tôi không nhận được)
- Không có lựa chọn (câu hỏi mở).

**4. Áp dụng review để cập nhật SDS lên v0.3 ngay chứ?**
- **Cập nhật SDS v0.3**: Áp dụng danh sách thay đổi ở §9 và các quyết định ở §11 của 08-SDS-review.md để cập nhật 07-SDS-ui-design.md lên v0.3.
- **Để tôi đọc trước**: Khoan sửa, tôi đọc bản review trước.

**5. Commit 07 và 08 lên một branch docs mới chứ?**
- **Commit lên branch**: Tạo branch docs/ui-design-spec từ develop và commit docs/07-SDS-ui-design.md và docs/08-SDS-review.md.
- **Để tôi đọc trước**: Khoan commit, tôi đọc lại SDS v0.3 trước.

**6. "Merge main" là đưa nhánh này vào main, hay ý khác?**
- **Đã đủ, push + PR**: Nhánh đã có main rồi là đủ. Push nhánh và mở PR vào develop.
- **Merge vào main**: Merge nhánh docs/ui-design-spec vào main local (chưa push).
