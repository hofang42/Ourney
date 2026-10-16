---
name: lesson
description: Biến một lỗi sai khi làm Ourney thành bài học có hiệu lực — truy vì sao sai, đối chiếu rule, tài liệu và bài học cũ, ghi mới hoặc nâng cấp, và chặn bằng test hoặc CI nếu lỗi đã lọt vào code. Dùng NGAY khi user sửa lưng ("sai rồi", "không phải", "đã bảo rồi"), khi kết luận hoặc bản fix bị dữ liệu bác bỏ, khi CI đỏ vì thay đổi của Claude, hoặc khi user gõ /lesson.
argument-hint: "[mô tả ngắn lỗi]"
---

# Lesson — bài học từ lỗi sai (Ourney)

Lỗi user nêu: $ARGUMENTS (trống thì lấy lần user sửa lưng gần nhất trong phiên).

Mục tiêu: lần sau gặp tình huống giống vậy, Claude tự làm đúng mà không cần user nhắc. Bài học chỉ có giá trị khi có **dấu hiệu nhận biết** (thấy gì) và **hành động** (làm gì trước). "Cẩn thận hơn" không phải bài học.

**Bài học khác rule.** Bài học là ghi chú riêng của mình, nằm trong MEM. Rule của repo (`CLAUDE.md`, `.claude/rules/`) do thành viên khác phụ trách. Có rule thì Claude Code tự nạp, và rule thắng nếu mâu thuẫn với bài học. Skill này không chép, không viết, không sửa rule.

MEM = thư mục memory của phiên (mục Memory trong system prompt). File trong MEM là local, không commit.

## Quy trình

1. **Lọc trước:** chỉ ghi khi lỗi có thể lặp lại ở phiên khác. User chỉ làm rõ một yêu cầu vốn mơ hồ (Claude không làm trái điều đã được nói rõ) thì làm theo ý user, không ghi bài học.
2. **Ghi đúng sự việc:** Claude đã nói hoặc làm gì, user sửa thế nào (trích nguyên văn), dữ liệu nào bác bỏ, mất bao nhiêu lượt.
3. **Hỏi "vì sao mình sai" tới tận gốc**, rồi gọi tên loại gốc:

   | Loại gốc | Dấu hiệu |
   |---|---|
   | Có lệnh đo mà không chạy | viết sẵn lệnh kiểm chứng rồi kết luận bằng suy luận |
   | Dừng ở khác biệt đầu tiên | thấy một nghi phạm là chốt, không liệt kê hết các tầng (app → data layer → RLS → storage → mạng) |
   | Làm trái rule hoặc tài liệu đã có | trái `CLAUDE.md`, `.claude/rules/`, hoặc quy ước ghi trong `docs/` |
   | Bỏ qua bài học hoặc quyết định đã có | memory, ADR, TASKS §4 có sẵn mà không áp |
   | Hiểu sai ý user | user hỏi A, trả lời B |
   | Dựa trí nhớ thay vì docs | bịa API của plugin, version, flag |

4. **Đối chiếu rule và tài liệu trước, rồi mới tới bài học cũ:**
   - Lỗi trái một rule hoặc tài liệu đã có → bài học chỉ ghi dấu hiệu nhận biết và trỏ tới đó (vd. "SRS §6.4 mục 2"), không viết lại nội dung.
   - Lỗi cho thấy repo nên có rule mới → soạn đề xuất gửi người phụ trách rule, không tự viết rule vào skill hay memory.
   - Tìm bài học cũ: `grep -ril -E "<từ khoá 1>|<từ khoá 2>" MEM`. Đã có thì đây là TÁI PHẠM, sang bước 5 ở cấp cao hơn. Chưa có thì cấp 1.
5. **Thang leo thang của bài học.** Memory chỉ là ngữ cảnh, không ép được hành vi, nên tái phạm thì phải lên cấp:

   | Cấp | Khi nào | Làm gì |
   |---|---|---|
   | 1 | Lỗi lần đầu | Tạo memory `feedback` trong MEM |
   | 2 | Tái phạm dù đã có memory | Cập nhật memory: thêm ngày + "lần N", làm dấu hiệu nhận biết cụ thể hơn. Đề xuất đưa vào `~/.claude/CLAUDE.md` của chính mình |
   | 3 | Tái phạm dù đã ở CLAUDE.md, và máy kiểm được | Đề xuất hook (dùng skill `update-config`); hỏi user trước khi sửa settings |

6. **Lỗi đã lọt vào code thì chặn cả loại lỗi đó**, không chỉ sửa chỗ này:

   | Lỗi nằm ở | Chặn bằng | Lệnh chạy |
   |---|---|---|
   | Streak, `rules.dart`, validation (`packages/ourney_core/`) | test trong `packages/ourney_core/test/`; lỗi streak thì thêm case vào `docs/contracts/streak_vectors.json` | `dart test` |
   | Bảng, RLS, RPC, storage (`supabase/`) | pgTAP trong `supabase/tests/` | `supabase test db` |
   | App, data layer, sync (`apps/mobile/`) | test trong `apps/mobile/test/` | `flutter test` |
   | Loại lỗi CI hiện chưa bắt | đề xuất thêm step vào `.github/workflows/ci.yml` | chạy lại CI |

   Test nằm ngoài vùng sở hữu của người đang làm thì nêu chủ vùng cần review (TASKS §2).
7. **Viết hoặc cập nhật memory** theo khung, rồi thêm hoặc sửa dòng trong `MEM/MEMORY.md`:

   ```markdown
   ---
   name: <slug>
   description: <dấu hiệu nhận biết → hành động, một dòng>
   metadata:
     type: feedback
   ---

   <Bài học 1-2 câu, dạng "Khi thấy X thì làm Y trước khi Z".>

   **Why:** <ngày tuyệt đối> — <task ID nếu có, chuyện gì xảy ra, sai ở đâu, dữ liệu bác bỏ, hậu quả>.

   **How to apply:**
   - Dấu hiệu: <tình huống quan sát được>
   - Làm: <hành động cụ thể, kèm lệnh nếu có>
   - Đừng: <cách sai đã mắc>

   Rule, tài liệu liên quan: <tên rule hoặc file §mục, hoặc bỏ dòng này>
   Liên quan: [[...]]
   ```

   Gốc là bẫy kỹ thuật của Ourney (không phải cách Claude làm việc) thì dùng `type: project`.
8. **Nói với user:** chỗ sai, dữ liệu bác bỏ, đã lưu ở file nào, cấp mấy, có thêm test hay gate không, có đề xuất rule mới không. Đề xuất cấp 2, cấp 3 hoặc rule mới thì hỏi user có đồng ý không.
9. **Áp bài học ngay** cho phần còn lại của phiên, không đợi phiên sau.
